# TODO webcam
# cd ~
# sudo apt-get install subversion libjpeg62-turbo-dev imagemagick ffmpeg libv4l-dev cmake
# git clone https://github.com/jacksonliam/mjpg-streamer.git
# cd mjpg-streamer/mjpg-streamer-experimental
# export LD_LIBRARY_PATH=.
# make
# sudo /sbin/iptables -A INPUT -p tcp -i wlan0 ! -s 127.0.0.1 --dport 8080 -j DROP    # for ipv4
# sudo /sbin/ip6tables -A INPUT -p tcp -i wlan0 ! -s ::1 --dport 8080 -j DROP
# sudo apt-get install iptables-persistent
# sudo /sbin/ip6tables-save > /etc/iptables/rules.v6
# sudo /sbin/iptables-save > /etc/iptables/rules.v4
# ./mjpg_streamer -i "./input_uvc.so" -o "./output_http.so"
# ./mjpg_streamer -i "./input_uvc.so -y" -o "./output_http.so"
# ~/.octoprint/config.yaml
# webcam:
#   stream: http://<your Raspi's IP>:8080/?action=stream
#   snapshot: http://127.0.0.1:8080/?action=snapshot
#   ffmpeg: /usr/bin/ffmpeg
#/etc/rc.local
# /home/pi/scripts/webcam start
