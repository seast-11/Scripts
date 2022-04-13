#!/usr/bin/env python3
from time import sleep
from confluent_kafka.admin import AdminClient, NewTopic
from rediscluster import RedisCluster
import argparse
import getpass
import json
import subprocess
import wmi

KAFKA_BROKERS = {"dev": "dev-host", "qa": "qa-host"}
REDIS_HOSTS = {"dev": "dev-host", "qa": "qa-host"}

WINDOWS_SERVERS = {
    "dev": ["dev-server1", "dev-server2"],
    "qa": ["qa-server1", "qa-server2"],
}

REDIS_DEFAULT_PORT = 6379
REDIS_DEFAULT_KEYS = ["KEY1", "KEY2"]

K8_DEFAULT_PODS = ["pod1", "pod2"]

WINDOWS_DEFAULT_SERVICES = {"Service1", "Service2"}


class Config:
    def __init__(
        self,
        host,
        port,
        keys,
        force,
        redis_password,
        username,
        dev_mode,
        brokers,
        topics,
        pods,
        skipK8,
        skipRedis,
        skipKafka,
        skipNT,
        windows_user,
        windows_password,
        nt_services,
        windows_servers,
        environment,
        kafka_user,
        kafka_password,
    ):
        self.host = host
        self.port = port
        self.keys = keys
        self.force = force
        self.redis_password = redis_password
        self.username = username
        self.dev_mode = dev_mode
        self.brokers = brokers
        self.topics = topics
        self.pods = pods
        self.skipNT = skipNT
        self.skipK8 = skipK8
        self.skipRedis = skipRedis
        self.skipKafka = skipKafka
        self.windows_user = windows_user
        self.windows_password = windows_password
        self.nt_services = nt_services
        self.windows_servers = windows_servers
        self.environment = environment
        self.kafka_user = kafka_user
        self.kafka_password = kafka_password


def setup_parser():
    parser = argparse.ArgumentParser("parser")

    parser.add_argument("-o", "--pods", type=str)


def create_config(parser):
    args = parser.parse_args()
    keys = args.keys

    with open("./Topics.json", "r") as topics_json:
        topics = json.load(topics_json)

    skipK8 = args.skip and "k8" in args.skip
    skipNT = args.skip and "nt" in args.skip
    skipRedis = args.skip and "redis" in args.skip
    skipKafka = args.skip and "kafka" in args.skip

    print("ENV: %s" % (args.environment))

    config = Config(
        REDIS_HOSTS[args.environment],
        args.port,
        keys,
        args.force,
        args.redis_password,
        getpass.getuser(),
        args.ignore_dev_mode,
        KAFKA_BROKERS[args.environment],
        topics,
        args.pods,
        skipK8,
        skipRedis,
        skipKafka,
        skipNT,
        args.windows_user,
        args.windows_password,
        args.nt_services,
        WINDOWS_SERVERS[args.environment],
        args.environment,
        args.kafka_user,
        args.kafka_password,
    )

    return config


def create_redis_db(config):
    db = RedisCluster(
        host=config.host,
        port=config.port,
        password=config.redis_password,
        ssl=True,
        skip_full_coverage_check=True,
    )

    return db


def create_kafka_admin(config):
    if config.environment == "dev":
        admin = AdminClient({"bootstrap.servers": config.brokers})
    else:
        admin = AdminClient(
            {
                "bootstrap.servers": config.brokers,
                "security.protocol": "sasl_ssl",
                "sasl.mechanism": "SCRAM-SHA-512",
                "sasl.username": config.kafka_user,
                "sasl.password": config.kafka_password,
            }
        )

    return admin


def redis_delete_keys(db, config):
    for key in config.keys:
        deleted = db.delete(key)
        if deleted == 1:
            print("Deleted key %s" % (key))
        else:
            print("Key %s not found" % (key))


def kafka_create_topics(admin, config):
    new_topics = []

    for topic in config.topics:
        new_topics.append(
            (
                NewTopic(
                    topic["Name"],
                    num_partitions=topic["NumPartitions"],
                    replication_factor=topic["ReplicationFactor"],
                    config=topic["Configs"],
                )
            )
        )

    fs = admin.create_topics(new_topics)

    for topic, f in fs.items():
        try:
            f.result()
            print("Topic {} created".format(topic))
        except Exception as e:
            print("Failed to crate topic: {}: {}".format(topic, e))


def kafka_delete_topics(admin, config):
    delete_topics = []

    for topic in config.topics:
        delete_topics.append(topic["Name"])

    fs = admin.delete_topics(delete_topics, operation_timeout=30)

    for topic, f in fs.items():
        try:
            f.result()
            print("Topic {} deleted.".format(topic))
        except Exception as e:
            print("Failed to delete topic {}. Exception:{}".format(topic, e))


def switch_k8_context(config):
    result = subprocess.run(
        [
            "kubectl",
            "config",
            "use-context",
            config.environment,
        ],
        capture_output=True,
        text=True,
    )
    print(result.stdout)
    print(result.stderr)


def scale_pods(pods, replicas):
    for pod in pods:
        result = subprocess.run(
            [
                "kubectl",
                "scale",
                "deployment",
                "-n",
                "name",
                pod + "web-app",
                "--replicas",
                replicas,
            ],
            capture_output=True,
            text=True,
        )
        print(result.stdout)
        print(result.stderr)


def confirm_action(config):
    print("Dev_mode:%s Username:%s" % (not config.dev_mode, config.username))

    if not config.skipRedis:
        print("Redis Host:%s" % (config.host))
        print("Redis keys to delete:")
        for key in config.keys:
            print(key)

    if not config.skipKafka:
        print("Kafka Broker:%s" % (config.brokers))
        print("Kafka topics to delete/create:")
        for topic in config.topics:
            print(topic["Name"])

    if not config.skipK8:
        print("K8 pods to stop/start:")
        for pod in config.pods:
            print(pod)

    if not config.skipNT:
        print("Windows servers to connect to:")
        for server in config.windows_servers:
            print(server)
        print("NT services to start/stop:")
        for nt in config.nt_services:
            print(nt)

    if not config.force:
        answer = input("Are you sure?")
        if answer != "y":
            return False

    return True


def stop_nt_services(config):
    for server in config.windows_servers:
        print("Connected to {}".format(server))
        for nt_service in config.nt_services:
            try:
                connection = wmi.WMI(
                    server, user=config.windows_user, password=config.windows_password
                )
            except Exception as e:
                print(
                    "Connection to {} not established. Aborting stop. Exception:{}".format(
                        server, e
                    )
                )
                return False
            for service in connection.Win32_Service():
                if nt_service == service.Name:
                    try:
                        if service.State == "Running":
                            print(
                                "Service {} found. Stopping service now".format(
                                    nt_service
                                )
                            )
                            service.StopService()
                            break
                        else:
                            print("Service {} already stopped.".format(nt_service))
                            break
                    except Exception as e:
                        print(
                            "Stop of service {} failed. Aborting stop. Exception:{}".format(
                                nt_service, e
                            )
                        )
                        return False


def start_nt_services(config):
    for server in config.servers:
        print("Connected to {}.".format(server))
        for nt_service in config.nt_services:
            try:
                connection = wmi.WMI(
                    server, user=config.windows_user, password=config.windows_password
                )
            except Exception as e:
                print(
                    "Connection to {} not established. Aborting start. Exception:{}".format(
                        server, e
                    )
                )
                return False
            for service in connection.Win32_Service():
                if nt_service == service.Name:
                    try:
                        if service.State == "Running":
                            print("Service {} already running.".format(nt_service))
                            break
                        else:
                            print(
                                "Service {} not running. Starting service now".format(
                                    nt_service
                                )
                            )
                            service.StartService()
                            break
                    except Exception as e:
                        print(
                            "Starting of service {} failed. Aborting start. Exception:{}".format(
                                nt_service, e
                            )
                        )
                        return False


def main():
    parser = setup_parser()
    config = create_config(parser)
    confirm = confirm_action(config)

    if not confirm:
        exit(-1)

    if not config.skipNT:
        stop_nt_services(config)

    if not config.skipK8:
        switch_k8_context(config)
        scale_pods(config.pods, "0")

    if not config.skipRedis:
        db = create_redis_db(config)
        redis_delete_keys(db, config)

    if not config.skipKafka:
        admin = create_kafka_admin(config)
        kafka_delete_topics(admin, config)

        print("sleeping for 5 seconds before creating topics...")
        sleep(5)

    if not config.skipNT:
        start_nt_services(config)

    if not config.skipK8:
        scale_pods(config.pods, "1")


if __name__ == "__main__":
    main()
