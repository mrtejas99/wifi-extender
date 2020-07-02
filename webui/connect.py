import re
from wifi import Cell, Scheme
import wifi.subprocess_compat as subprocess
from wifi.utils import ensure_file_exists

class SchemeWPA(Scheme):

    interfaces = "/etc/wpa_supplicant/wpa_supplicant-wlan1.conf"

    def __init__(self, interface, name, options=None):
        self.interface = interface
        self.name = name
        self.options = options or {} 

    def __str__(self):
        options = ''.join("\n    {k}=\"{v}\"".format(k=k, v=v) for k, v in self.options.items())
        return "network={" + options + '\n}\n'

    def __repr__(self):
            return 'Scheme(interface={interface!r}, name={name!r}, options={options!r}'.format(**vars(self))
            
    def save(self):
        """
        Writes the configuration to the :attr:`interfaces` file.
        """
        if not self.find(self.interface, self.name):
            with open(self.interfaces, 'a') as f:
                f.write('\n')
                f.write(str(self))        

    @classmethod
    def all(cls):
        """
        Returns an generator of saved schemes.
        """
        ensure_file_exists(cls.interfaces)
        with open(cls.interfaces, 'r') as f:
            return extract_schemes(f.read(), scheme_class=cls) 
    def activate(self):
        """
        Connects to the network as configured in this scheme.
        """

        subprocess.check_output(['/sbin/ifdown', self.interface], stderr=subprocess.STDOUT)
        ifup_output = subprocess.check_output(['/sbin/ifup', self.interface] , stderr=subprocess.STDOUT)
        ifup_output = ifup_output.decode('utf-8')

        return self.parse_ifup_output(ifup_output)
    def delete(self):
        """
        Deletes the configuration from the /etc/wpa_supplicant/wpa_supplicant-wlan1.conf file.
        """
        content = ''
        with open(self.interfaces, 'r') as f:
            lines=f.read().splitlines()
            while lines:
                line=lines.pop(0)

                if line.startswith('#') or not line:
                    content+=line+"\n"
                    continue

                match = scheme_re.match(line)
                if match:
                    options = {}
                    ssid=None
                    content2=line+"\n"
                    while lines and lines[0].startswith(' '):
                        line=lines.pop(0)
                        content2+=line+"\n"
                        key, value = re.sub(r'\s{2,}', ' ', line.strip()).split('=', 1)
                        #remove any surrounding quotes on value
                        if value.startswith('"') and value.endswith('"'):
                            value = value[1:-1]
                        #store key, value
                        options[key] = value
                        #check for ssid (scheme name)
                        if key=="ssid":
                            ssid=value
                    #get closing brace        
                    line=lines.pop(0)
                    content2+=line+"\n"

                    #exit if the ssid was not found so just add to content
                    if not ssid:
                        content+=content2
                        continue
                    #if this isn't the ssid then just add to content
                    if ssid!=self.name:
                        content+=content2

                else:
                    #no match so add content
                    content+=line+"\n"
                    continue

        #Write the new content
        with open(self.interfaces, 'w') as f:
            f.write(content)    


scheme_re = re.compile(r'network={\s?')

#override extract schemes
def extract_schemes(interfaces, scheme_class=SchemeWPA):
    lines = interfaces.splitlines()
    while lines:
        line = lines.pop(0)
        if line.startswith('#') or not line:
            continue

        match = scheme_re.match(line)
        if match:
            options = {}
            interface="wlan1"
            ssid=None

            while lines and lines[0].startswith(' '):
                key, value = re.sub(r'\s{2,}', ' ', lines.pop(0).strip()).split('=', 1)
                #remove any surrounding quotes on value
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                #store key, value
                options[key] = value
                #check for ssid (scheme name)
                if key=="ssid":
                    ssid=value

            #exit if the ssid was not found
            if ssid is None:
                continue
            #create a new class with this info
            scheme = scheme_class(interface, ssid, options)

            yield scheme
