#!/usr/bin/python

# Simple script to control General Purpose I/O (GPIO) pins on BBB

import argparse
import Adafruit_BBIO.GPIO as GPIO


program_description = 'Program to control GPIO channel on BBB'
program_version = '0.1'

parser = argparse.ArgumentParser(description = program_description)
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('-c', '--channel', help='PWM Channel ID. '\
	'It can be specified in the form of P8_17, or GPIO27', required=True)
requiredNamed.add_argument('-d', '--direction', help='0:input, 1:output',\
 required=True, type=int)
parser.add_argument('-p', '--pullupdown', help='Valid on input ports.'\
	' 0 for off, 1 for pull-down, 2 for pull-up', default=0, type=int)
parser.add_argument('-o', '--output', help='Valid on output ports only.'\
	' Set to 0 or 1', default=0, type=int)
parser.add_argument('-e', '--edge', help='Wait for edge detection on input'\
	' port. Default 0 (disable), 1 to enable', default=0, type=int)
parser.add_argument('-t', '--timeout', help='Use when --edge is enabled. '\
	'Time to wait for an edge, in milliseconds. '\
	'-1 (default) will wait forever.', default=-1, type=int)
parser.add_argument("-V", "--version", help="show program version",
 action="store_true")
args = parser.parse_args()

if args.version:
    print("program version {}".format(program_version))

if args.edge == 1:
    GPIO.setup(args.channel, GPIO.IN, GPIO.PUD_OFF)
    print GPIO.wait_for_edge(args.channel, GPIO.BOTH, args.timeout)
    exit(0)
elif args.direction == 0:
    GPIO.setup(args.channel, GPIO.IN, args.pullupdown)
    print GPIO.input(args.channel)
    exit(0)
else:
    GPIO.setup(args.channel, GPIO.OUT, GPIO.PUD_OFF, args.output)