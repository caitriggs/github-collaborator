from __future__ import print_function
from flask import Flask, request, render_template
from werkzeug import secure_filename
import pandas as pd
import numpy as np
import requests
import sys


app = Flask(__name__)


@app.route('/')
def home():
    return render_template('index.html')

@app.route('/madrury')
def get_madrury():
    return render_template('madrury.html')

@app.route('/torvalds')
def get_torvalds():
    return render_template('torvalds.html')

if __name__ == '__main__':
    app.run(port=5001)
