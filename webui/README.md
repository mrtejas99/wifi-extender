<h1 id="webui">WebUI</h1>
<p>This webUI is specifically designed to dynamically connect to a WiFi AP using the browser. </p>

<img src="https://i.imgur.com/rklcvAY.png" alt="webui" />

<h2 id="usage">Usage</h2>
<ol>
<li>Connect to Access point created by the Raspberry Pi.</li>
<li>Open up a browser and navigate to <a href="http://raspberrypi.local:5000">http://raspberrypi.local:5000</a></li>
<li>Fill up the <code>SSID</code> and the <code>psk</code>
<li>Click the connect button. Wait for some time(2-3 minutes). Pi will restart itself and now it is good to go!</li>
</ol>

<h2 id="dependencies">Dependencies</h2>
<ul>
<li>Python 3.x</li>
<li><a href="https://pypi.org/project/wifi/">wifi</a></li>
<li><a href="https://pypi.org/project/Flask/">flask</a></li>
</ul>

<h2 id="howto">How to use</h2>
<ul>
<li>Navigate to the <code>webui</code> directory using <code>cd webui</code></li>
<li>Run the command <code>sudo python app.py</code> </li>
</ul>
<p>You can set the server to auto-start on boot using <code>systemd</code>
<ul>
<li>Create a file called <code>server.service</code> using <code>cd sudo nano /lib/systemd/system/server.service</code></li>
<li>Add the following contents to the file </li>

<pre class=" language-bash"><code>[Unit]
 Description=WiFi conf server
 After=multi-user.target

 [Service]
 Type=idle
 ExecStart=/usr/bin/python3 /home/pi/webui/app.py

 [Install]
 WantedBy=multi-user.target
</code></pre>

<li>Enable the service using <code>sudo systemctl enable server</code></li>
<li>Start the service using <code>sudo systemctl start server</code></li>
</ul>
