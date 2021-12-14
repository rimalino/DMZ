sudo apt update
sudo UCF_FORCE_CONFOLD=1 DEBIAN_FRONTEND=noninteractive apt install -y bird --fix-missing
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0 
sudo sysctl -w net.ipv4.conf.all.send_redirects=0

sudo sysctl -p /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING ! -d '10.0.0.0/8' -o eth0 -j MASQUERADE

cat <<EOF > bird.conf
log syslog all;
router id 10.0.0.68;
protocol device {
        scan time 10;
}
protocol direct {
      disabled;
}
protocol kernel {
      preference 254;
      learn;
      merge paths on;
      import filter {
          reject;
      };
      export filter {
          reject;
      };
}
protocol static {
      import all;
      route 0.0.0.0/0 via 10.0.0.65;
      route 0.0.0.0/1 via 10.0.0.65;
      route 128.0.0.0/1 via 10.0.0.65;
}
protocol bgp rs0 {
      description "RouteServer instance 0";
      multihop;
      local 10.0.0.68 as 65001;
      neighbor 10.0.0.4 as 65515;
          import filter {accept;};
          export filter {accept;};
}
protocol bgp rs1 {
      description "Route Server instance 1";
      multihop;
      local 10.0.0.68 as 65001;
      neighbor 10.0.0.5 as 65515;
          import filter {accept;};
          export filter {accept;};
}
EOF
sudo mv bird.conf /etc/bird/bird.conf
sudo systemctl restart bird