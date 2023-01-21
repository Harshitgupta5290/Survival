import pygame
from pygame import mixer
import os
import random
import csv
import button

nixer.init() pygame.init()

9

13

SCREEN WIDTH = 900

SCREEN_HEIGHT= int(SCREEN_WIDTH 0.8)

screen= pygame.display.set_mode ((SCREEN_WIDTH, SCREEN_HEIGHT))

pygane.display.set_caption('SURVIVAL A HUNTER )

14

15

24°C Sn

#set framerate

clock pygane.tine.Clock() FPS = 60

#define gane variables

GRAVITY 0.75

SCROLL THRESH = 200

ROWS - 10

COLS - 150