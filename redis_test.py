#!/usr/bin/env python3

import redis
import argparse
import getpass


DEFAUT_HOST = "localhost"
DEFAULT_PORT = 6379
DEFAULT_KEYS = ["first", "last"]


class Config:
    def __init__(self, host, port, keys, force):
        self.host = host
        self.port = port
        self.keys = keys
        self.force = force


def setup_parser():
    parser = argparse.ArgumentParser("Amazing script thingy")
    parser.add_argument(
        "-H",
        "--host",
        type=str,
        required=False,
        help="database hostname",
        metavar="",
        default=DEFAUT_HOST,
    )
    parser.add_argument(
        "-p",
        "--port",
        type=int,
        required=False,
        help="database port",
        metavar="",
        default=DEFAULT_PORT,
    )
    parser.add_argument(
        "-d",
        "--dev_mode",
        type=str,
        required=False,
        help="append username to keys if dev_mode is True",
        metavar="",
        choices=("True", "False"),
        default="True",
    )
    parser.add_argument(
        "--force",
        required=False,
        help="ignore confirmation prompt",
        dest="force",
        action="store_true",
    )
    parser.add_argument(
        "-k",
        "--keys",
        type=str,
        required=False,
        help="list of keys to delete",
        nargs="+",
        metavar="",
        default=DEFAULT_KEYS,
    )

    return parser


def create_config(parser):
    args = parser.parse_args()
    keys = args.keys

    if args.dev_mode == "True":
        for index, key in enumerate(keys):
            keys[index] = key + "-" + getpass.getuser()

    config = Config(args.host, args.port, keys, args.force)

    return config


def delete_keys(db, keys):
    for key in keys:
        deleted = db.delete(key)
        if deleted == 1:
            print("Deleted key %s" % (key))


def set_keys(db, keys):
    for key in keys:
        db.set(key, "UNCLE FREDDY DIED!")
        value = db.get(key)
        print("Set value:%s for key:%s" % (value, key))


if __name__ == "__main__":
    parser = setup_parser()
    config = create_config(parser)

    db = redis.Redis(host=config.host, port=config.port)

    print("Host:%s Keys:%s" % (config.host, config.keys))

    if not config.force:
        answer = input("Are you sure you want to delete keys?")
        if answer != "y":
            exit(-1)

    delete_keys(db, config.keys)
    set_keys(db, config.keys)
