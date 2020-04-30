<h1 id="truly-wifi-extender">Truly WiFi Extender</h1>
<p><img src="https://i.imgur.com/J3TLIIc.png" alt="Graphical Visualisation"></p>
<h2 id="introduction">Introduction</h2>
<p>Truly WiFi Extender is a WiFi repeater based on Raspberry Pi Zero W. It makes a nice alternative to a commercial WiFi repeater combining low-cost (under 10USD) and highly customizable software. It can also run some ad-blocking solutions such as <a href="https://github.com/pi-hole/pi-hole/">pi- hole</a> as well. This project is one of a kind because most of the projects on GitHub demonstrate how to create a wireless AP to share Internet access obtained using Ethernet.</p>
<h2 id="hardware">Hardware</h2>
<p>This will run on any version of Raspberry Pi. But make sure to have two wifi adapters. Nowadays, Raspberry Pi comes with onboard WiFi. In case you have an older version, you might have to use two USB WiFi adapters. I will be using a single USB WiFi adapter since I am using Raspberry Pi Zero W.</p>
<h2 id="software">Software</h2>
<p>For this project, I will be using Raspbian Stretch Lite. You can download it on the official <a href="https://www.raspberrypi.org/downloads/raspbian/">Raspberry Pi website</a>.  You can use the newer version of Raspbian as well.</p>
<p>The main packages on which this project is <code>wpa_supplicant</code>. Since Raspbian is Linux based and uses  <code>wpa_supplicant</code>  to manage WiFi cards, we can easily set up this computer as a WiFi access point. You even don’t need  <a href="http://w1.fi/hostapd">hostapd</a>  - just  <code>wpa_supplicant</code>  and <code>systemd-networkd</code></p>
<h2 id="implementation">Implementation</h2>
<h3 id="prerequisites">Prerequisites</h3>
<p>For flashing the image onto the SD card I have used <a href="https://github.com/balena-io/etcher">BalenaEtcher</a><br>
<img src="https://i.imgur.com/BzkTYVq.png" alt="BalenaEtcher Window"></p>
<ol>
<li>Download the raspbian lite<code>.iso</code> file from  the  <a href="https://www.raspberrypi.org/downloads/raspbian/">Raspberry Pi website</a></li>
<li>Once downloaded, open BalenaEtcher, select the <code>.iso</code> file, select the SD card and click the <strong>flash</strong> button and wait for the process to finish.</li>
<li>Then, open the <strong>boot</strong> partition and inside it, create a blank text file named <code>ssh</code> with no extension.</li>
<li>Finally, create another text file called <code>wpa_supplicant.conf</code> in the same <code>boot</code>  partition and paste the following content.</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash">ctrl_interface<span class="token operator">=</span>DIR<span class="token operator">=</span>/var/run/wpa_supplicant GROUP<span class="token operator">=</span>netdev
update_config<span class="token operator">=</span>1
country<span class="token operator">=</span>IN

network<span class="token operator">=</span><span class="token punctuation">{</span>
     ssid<span class="token operator">=</span><span class="token string">"mywifissid"</span>
     psk<span class="token operator">=</span><span class="token string">"mywifipassword"</span>
     key_mgmt<span class="token operator">=</span>WPA-PSK
<span class="token punctuation">}</span>
</code></pre>
<p>Replace  the <em>mywifissid</em> with the name of the WiFi and <em>mywifipassword</em> with the wifi password.<br>
5. Power on the Raspberry pi. To find its IP, you can use a tool like <a href="https://angryip.org/download/#windows">Angry IP Scanner</a>  and scan the subnet,<br>
6. Once you find the IP, SSH to your Pi using a tool like <a href="https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html">PuTTY</a> or just <code>ssh pi@raspberrypi.local</code>, enter the password <code>raspberry</code> and you are good to go.<br>
5. Finally, update the package list and upgrade the packages and reboot Pi.</p>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> apt update -y
<span class="token function">sudo</span> apt upgrade -y
<span class="token function">sudo</span> <span class="token function">reboot</span>
</code></pre>
<h3 id="setting-up-systemd-networkd">Setting up <code>systemd-networkd</code></h3>
<p>From <a href="https://wiki.archlinux.org/index.php/Systemd-networkd">ArchWiki</a></p>
<blockquote>
<p>systemd-networkd is a system daemon that manages network configurations. It detects and configures network devices as they appear; it can also create virtual network devices.</p>
</blockquote>
<p>To minimize the need for additional packages,<code>networkd</code> is used since it is already built into the <code>init</code> system, therefore, no need for <code>dhcpcd</code>.</p>
<ol>
<li>Prevent the use of <code>dhcpd</code><br>
<em>Note: It is required to run as  <code>root</code></em></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> systemctl mask networking.service dhcpcd.service
<span class="token function">sudo</span> <span class="token function">mv</span> /etc/network/interfaces /etc/network/interfaces~
<span class="token function">sed</span> -i <span class="token string">'1i resolvconf=NO'</span> /etc/resolvconf.conf
</code></pre>
<ol start="2">
<li>Use the inbuilt <code>systemd-networkd</code></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> systemctl <span class="token function">enable</span> systemd-networkd.service systemd-resolved.service
<span class="token function">sudo</span> <span class="token function">ln</span> -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
</code></pre>
<h3 id="configuring-wpa-supplicant">Configuring wpa-supplicant</h3>
<h4 id="wlan0-as-ap">wlan0 as AP</h4>
<ol>
<li>Create a new file using the command.</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> <span class="token function">nano</span> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
</code></pre>
<ol start="2">
<li>Add the following content and save the file by pressing <kbd>Ctrl</kbd><kbd>X</kbd>, <kbd>Y</kbd>and <kbd>Enter</kbd></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash">country<span class="token operator">=</span>IN
ctrl_interface<span class="token operator">=</span>DIR<span class="token operator">=</span>/var/run/wpa_supplicant GROUP<span class="token operator">=</span>netdev
update_config<span class="token operator">=</span>1

network<span class="token operator">=</span><span class="token punctuation">{</span>
    ssid<span class="token operator">=</span><span class="token string">"TestAP-plus"</span>
    mode<span class="token operator">=</span>2
    key_mgmt<span class="token operator">=</span>WPA-PSK
    psk<span class="token operator">=</span><span class="token string">"12345678"</span>
    frequency<span class="token operator">=</span>2412
<span class="token punctuation">}</span>
</code></pre>
<p>Replace  the <em>TestAP-plus</em>  and <em>12345678</em> with your desired values.</p>
<p>This configuration file is to be used for the onboard wifi Adapter <code>wlan0</code> which will be used to create a wireless access point.</p>
<ol start="3">
<li>Give the user read, write permissions to the file</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> <span class="token function">chmod</span> 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
</code></pre>
<ol start="4">
<li>Restart <code>wpa_supplicant</code> service</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> systemctl disable wpa_supplicant.service
<span class="token function">sudo</span> systemctl <span class="token function">enable</span> wpa_supplicant@wlan0.service
</code></pre>
<h4 id="wlan1-as-client">wlan1 as client</h4>
<ol>
<li>Create a new file using the command.</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> <span class="token function">nano</span> /etc/wpa_supplicant/wpa_supplicant-wlan1.conf
</code></pre>
<ol start="2">
<li>Add the following content and save the file by pressing <kbd>Ctrl</kbd><kbd>X</kbd>, <kbd>Y</kbd>and <kbd>Enter</kbd></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash">country<span class="token operator">=</span>IN
ctrl_interface<span class="token operator">=</span>DIR<span class="token operator">=</span>/var/run/wpa_supplicant GROUP<span class="token operator">=</span>netdev
update_config<span class="token operator">=</span>1

network<span class="token operator">=</span><span class="token punctuation">{</span>
    ssid<span class="token operator">=</span><span class="token string">"Asus RT-AC5300"</span>
    psk<span class="token operator">=</span><span class="token string">"12345678"</span>
<span class="token punctuation">}</span>
</code></pre>
<p>Replace  the <em>Asus RT-AC5300</em>  and <em>12345678</em> with your Router SSID and password.</p>
<p>This configuration file is to be used for the USB WiFi Adapter <code>wlan01</code> which will be used to connect to a Wireless Router.</p>
<ol start="3">
<li>Give the user read, write permissions to the file</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> <span class="token function">chmod</span> 600 /etc/wpa_supplicant/wpa_supplicant-wlan1.conf
</code></pre>
<ol start="4">
<li>Restart <code>wpa_supplicant</code> service</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> systemctl disable wpa_supplicant.service
<span class="token function">sudo</span> systemctl <span class="token function">enable</span> wpa_supplicant@wlan1.service
</code></pre>
<h3 id="configuring-interfaces">Configuring Interfaces</h3>
<ol>
<li>Create a new file using the command.</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> <span class="token function">nano</span> /etc/systemd/network/08-wlan0.network
</code></pre>
<ol start="2">
<li>Add the following content and save the file by pressing <kbd>Ctrl</kbd><kbd>X</kbd>, <kbd>Y</kbd>and <kbd>Enter</kbd></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token punctuation">[</span>Match<span class="token punctuation">]</span>
Name<span class="token operator">=</span>wlan0
<span class="token punctuation">[</span>Network<span class="token punctuation">]</span>
Address<span class="token operator">=</span>192.168.7.1/24
IPMasquerade<span class="token operator">=</span>yes
IPForward<span class="token operator">=</span>yes
DHCPServer<span class="token operator">=</span>yes
<span class="token punctuation">[</span>DHCPServer<span class="token punctuation">]</span>
DNS<span class="token operator">=</span>1.1.1.1
</code></pre>
<ol start="3">
<li>Create a new file using the command.</li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token function">sudo</span> <span class="token function">nano</span> /etc/systemd/network/12-wlan1.network
</code></pre>
<ol start="4">
<li>Add the following content and save the file by pressing <kbd>Ctrl</kbd><kbd>X</kbd>, <kbd>Y</kbd>and <kbd>Enter</kbd></li>
</ol>
<pre class=" language-bash"><code class="prism  language-bash"><span class="token punctuation">[</span>Match<span class="token punctuation">]</span>
Name<span class="token operator">=</span>wlan1
<span class="token punctuation">[</span>Network<span class="token punctuation">]</span>
DHCP<span class="token operator">=</span>yes
</code></pre>
<ol start="5">
<li>Reboot the Raspberry Pi using <code>sudo reboot</code></li>
</ol>
<h2 id="references">References:</h2>
<ul>
<li><a href="https://wiki.archlinux.org/index.php/Systemd-networkd">systemd-networkd</a></li>
<li><a href="https://raspberrypi.stackexchange.com/questions/78787/howto-migrate-from-networking-to-systemd-networkd-with-dynamic-failover/78788#78788">how to migrate from networking to systemd networkd with dynamic failover</a></li>
<li><a href="https://linux.die.net/man/8/sudo">sudo man page</a></li>
<li></li>
</ul>

