#!/usr/bin/python

# Simple script to control ADC inputs on BBB

import argparse
import Adafruit_BBIO.ADC as ADC


program_description = 'Program to read adc channel on BBB.'\
' It returns normalized values from 0 to 1.0 (1 == 1.8volts)'
program_version = '0.1'

parser = argparse.ArgumentParser(description = program_description)
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('-c', '--channel', help='ADC Channel ID.'\
' It can be specified in the form of P9_33, or AIN4', required=True)
parser.add_argument("-V", "--version", help="show program version",
 action="store_true")
args = parser.parse_args()

if args.version:
    print("program version {}".format(program_version))

ADC.setup()
print ADC.read(args.channel)