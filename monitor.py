#!/usr/bin/env python
#
# Copyright (C) 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

'''
'''

import json
import os

import paho.mqtt.client as mqtt


class MqttClient:
    def __init__(self, spool_dir):
        self.client = mqtt.Client()
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.spool_dir = spool_dir

    # The callback for when the client receives a CONNACK response
    # from the server.
    def on_connect(self, client, userdata, flags, rc):
        print("Connected with result code " + str(rc))

        # Subscribing in on_connect() means that if we lose the connection and
        # reconnect then subscriptions will be renewed.
        client.subscribe("gerrit/+/+/patchset-created")
        client.subscribe("gerrit/+/+/change-merged")
        client.subscribe("gerrit/+/+/change-abandoned")

    # The callback for when a PUBLISH message is received from the server.
    def on_message(self, client, userdata, msg):
        data = json.loads(str(msg.payload))
        if data['change']['branch'] == 'master':
            fname = os.path.join(self.spool_dir, data['change']['number'])
            with open(fname, 'w') as f:
                f.write(str(msg.payload))

    def loop_forever(self, server, port, timeout):
        self.client.connect(server, port, timeout)

        # Blocking call that processes network traffic, dispatches
        # callbacks and handles reconnecting.
        # Other loop*() functions are available that give a threaded
        # interface and a manual interface.
        self.client.loop_forever()

if __name__ == "__main__":
    import sys

    client = MqttClient(sys.argv[1])
    client.loop_forever("firehose.openstack.org", 1883, 60)

# monitor.py ends here
