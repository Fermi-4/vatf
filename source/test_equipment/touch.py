#!/usr/bin/python

# Simple script to control 3 servos that drive TapBot

import time
import sys
import Adafruit_BBIO.PWM as PWM

servo1_pin = "P9_16"
servo2_pin = "P9_22"
servo3_pin = "P8_13"

duty_min = 3
duty_max = 14.5
duty_span = duty_max - duty_min


def angle_to_duty(angle):
    angle_f = float(angle)
    duty = 100 - ((angle_f / 180) * duty_span + duty_min)
    return duty;


def touch_servo(servo, duty):
   print "Entering func: servo:", servo, ", duty:", duty
   if servo == 1:
      PWM.set_duty_cycle(servo1_pin, duty)
   elif servo == 2:
      PWM.set_duty_cycle(servo2_pin, duty)
   elif servo == 3:
      PWM.set_duty_cycle(servo3_pin, duty)
   return;

def set_servos(settings):
   for setting in settings:
      servo_id = setting.keys()[0]
      angle = setting.values()[0]
      duty = angle_to_duty(angle)
      touch_servo(servo_id, duty)
      time.sleep(.05)


def reset_servo():
   duty = angle_to_duty(90)
   for i in range(1,4):
      touch_servo(i, duty)
   return;


def init_servo():
   PWM.start(servo1_pin, 0.0, 60, 1)
   PWM.start(servo2_pin, 0.0, 60, 1)
   PWM.start(servo3_pin, 0.0, 60, 1)
   reset_servo()
   return;

def usage():
   print "touch.py <servo_id:angle 0-90> [<servo_id:angle 0-90> ...]"
   exit(1)

def check_inputs():
   settings = []
   if len(sys.argv) < 4:
      usage()
   for i in range(1,4):
      val = sys.argv[i]
      if not ':' in val:
         usage()
      servo_id,angle = val.split(':')
      servo_id = int(servo_id)
      angle = int(angle)
      if angle < 0 or angle > 90 or servo_id < 0:
         usage()
      else:
         settings.append({servo_id:angle})
   return settings


#Main logic
settings = check_inputs()
init_servo()
time.sleep(1)
set_servos(settings)
time.sleep(1)
reset_servo()
exit(0)