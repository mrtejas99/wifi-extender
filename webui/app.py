from flask import Flask,render_template,request,make_response
import subprocess
import os
import connect

app = Flask(__name__)
    
@app.route("/")
def landing():
    return render_template("index.html")

@app.route("/connect", methods=["POST"])
def repeaterConf():    
    ssid = request.form['ssid']
    password = request.form['pass']
    scheme = connect.SchemeWPA('wlan1', ssid, {"ssid": ssid,"psk": password})
    scheme.save()
    
    subprocess.Popen(['shutdown','-r','now'])
    
if __name__=="__main__":
    app.run(debug=True,host='0.0.0.0')