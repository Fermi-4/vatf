#!/usr/bin/python

# Simple script to control PWM outouts on BBB

import argparse
import Adafruit_BBIO.PWM as PWM


program_description = 'Program to control pwm channel on BBB'
program_version = '0.1'

parser = argparse.ArgumentParser(description = program_description)
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('-c', '--channel', help='PWM Channel ID. '\
    'It can be specified in the form of P8_10, or EHRPWM2A', required=True)
requiredNamed.add_argument('-d', '--duty', help='Duty cycle. It must '\
	'have a value from 0 to 100', required=True, type=int)
parser.add_argument('-f', '--frequency', help='PWM frequency, in Hz. '\
	'It must be greater than 0, default=2000', default=2000, type=int)
parser.add_argument('-p', '--polarity', help='defines whether the value for '\
	'duty_cycle affects the rising edge or the falling edge of the waveform.'\
	' Allowed values: 0 (rising edge, default) or 1 (falling edge)',\
	 default=0, type=int)
parser.add_argument('-s', '--stop', help='Stop generating PWM signal,'\
	' default =0', default=0, type=int)
parser.add_argument("-V", "--version", help="show program version",\
	action="store_true")
args = parser.parse_args()

if args.version:
    print("program version {}".format(program_version))

if args.stop == 1:
    PWM.start(args.channel, args.duty)
    PWM.stop(args.channel)
    exit(0)

PWM.start(args.channel, args.duty, args.frequency, args.polarity)