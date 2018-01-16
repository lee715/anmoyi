'use strict'

const net = require('net');


exports.newDevice = function () {
  const client = net.createConnection({ port: 7000 }, () => {
    //'connect' listener
    console.log('connected to server!');
    client.write('world!\r\n');
  });
  client.on('data', (data) => {
    console.log(data.toString());
  });
  client.on('end', () => {
    console.log('disconnected from server');
  });
  setInternal(function () {
    client.write('~u001#OK!')
  }, 30000)
}