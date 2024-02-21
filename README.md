# solaris_camera_test

here is what my apporach was initially:
- to make the app that can access the camera
- encode the image
- send it over the network
- make a web server
- establish a connection between the device and the server
- make a web app to decode the image 

What I did in this approach:
- I was able make the app that was able to access my phone camera
- I read about web sockets and implemented the flutter web_socket_channel, which did not work out.
- I read about flutter_webRTC for real time communicaiton, which did not turn out to be a feasable solution becasuse of the requirement of the STUN servers.
- I tried making the websocket using python. I had imported asyncio and websocket, but for some reason, python server did not start. I thought it was an issue because of my IP but it was not. It was an OS error python was giving me. 
- I tried making the websocket using node.jS. Which I was successfuly able to do so but my flutter app was not able to connect to the server and kept on crashing. Tried debugging the app, the problem was poor error handling which lead to a run time error.

Since this approach did not work, I tried using a different approach: 
- make the server in node and start the server 
- make a flutter app that would connect to the server using web sockets
- ensure successful connection
- access camera
- encode the image 
- prepare the server to recieve the image
- make the web app that would decode the image
- send the image over the network

What was I able to do in this approach:
- made the server, started the server
- made the flutter app and established a successful connection with the server
- was able to send messages and recieve messages from the server. 

What I am working on:
- encoding the image 
- prepare the server to recieve the image
- make web app
- send the image over the network
