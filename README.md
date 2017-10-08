# Mobile_Assignment
This repository is used to manage the source code of COMP90018 Mobile Computing Systems Programming Assignment 2

// COMP90018 Mobile Computing Assgnment2
// IOS Mobile APP: Homie  - Become your safe companions on your way.
// Group Member:
// 732329 Jinghan Liang
// 732355 Zhen Jia
// 764696 Renyi Hou
//
//  Created by group:homie on 2017/9/20.
//  Copyright © 2017 group:Homie. All rights reserved.

=================================================================================================

Mobile App Introduction:

This is an IOS Mobile App to enable safety about decision-making. Your can get first a route direction powered by Google Map API. Then You can invite your friends to become your companions, which means they can monitor your location in real-time. Once you feel nervous on your way to somewhere, you can sent for help during anytime you using the app, through sending alert message to your companions or call police directly. The creative point that your phone can detect your motion automatically. If you shake your phone accidentally on intentionally, your phone will pop up an alert view on that there is a 15 seconds counter down. If you confirm your safe during the time, nothing happened, but if you don't respond, your app will send directly "you are in danger" message to your companions. 

Your companions can access your start location, destination, route, transportation mode and real-time location by typing correctly your username and accesscode that you sent to them. They can also obtain your time and distance rest to your location. 

If you arrive your destination, you should "end your trip" by clicking "I've arrived safely", then your friends will be notified.

=================================================================================================

The introduction of four view controller

//LoginViewController.swift
This is the entry point of the mobile app. It controls the login-about function. Send a query to Azure database about the typed login username and psw. Only when the result responded successfully, mapView board (main board) will be loaded.

//MapViewController.swift
//This controls the main load page, implemented the map-about function, including: places selection, start and end route direction, transport modes transfer, help-about functions, especially detecting the phone's shaking or not.Here also is a entry to "add companions" board.

//AddCompanionViewController.swift
This is the board for whom aiming to add friends as his/her companions. This board will show the user's friends list by querying the database according to user's id. After selected, it sends messages to the selected friends. Within the msg, there is user's name and accesscode.

//MonitorViewController.swift
This is the board for whom aiming to monitor friend's location (to become the friend's companion) only if receiving the friend's msg with the friend's username and access code. Friend's location will be refreshed every 5 secs. On the map, it also shows the real-time location, the rest distance and time to destination
