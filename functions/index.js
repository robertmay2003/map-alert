// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendUpdateReminders = functions.https.onCall((eventTimeArg, marginArg, longitude, latitude, originLongitude,
																											originLatitude, transportation, repeats, daily, title, message, dateShown, id, token, context) => {
	const args = {
		eventTime: eventTimeArg,
		margin: marginArg,
		longitude: longitude,
		latitude: latitude,
		originLongitude: originLongitude,
		originLatitude: originLatitude,
		transportation: transportation,
		repeats: repeats,
		daily: daily,
		title: title,
		message: message,
		dateShown: dateShown,
		id: id,
		token: token
	};

	const payload = {
		notification: {
			title: args.title,
			body: args.message,
			userInfo: args.id
		}
	};
	const topic = "all";

	// Clear any preexisting checking intervals in case
	admin.database.ref('/'+args.token+'/'+args.id+'/checking_interval').once('value', (snapshot) => {
		clearInterval(snapshot.val());
	});

	// Set checking interval (every 5 minutes)
	var intervalId = null;
	var currentAlarmTimeout = null;
	intervalId = setInterval( function() {
		var setNotifications = null;
		var notificationsTime = null;
		// process time, decide whether or not to send notification
		// - set notificationTime to time of first notification (between 1 and 300, seconds between now and 5 minutes from now)
		// - set setNotifications to true or false depending on whether or not notifications should be set
		let today = new Date();
		let departureTime = today.getTime()+margin*1000;
		let requestURL = `https://maps.googleapis.com/maps/api/directions/json?origin=${args.originLatitude},${args.originLongitude}&destination=${args.latitude},${args.longitude}&mode=${args.transportation}&departure_time=${departureTime}&key=AIzaSyDrBVdxezWqWJJLDbFZZpDHAjwc-kLMGqA`
		var request = new XMLHttpRequest();

		request.open('GET', requestURL, true);
		request.onload = function () {
			// Make sure daily alarms have not been shown today
			// Make sure non daily alarms have not been shown before
			if (args.daily) {
				let date = new Date(args.dateShown * 1000);
				// If daily and alarm was already shown today, setNotifications = false
				if (date.year === today.year && date.month === today.month && date.day === today.day) {
					setNotifications = false
				}
			} else {
				if (!(isNan(args.dateShown))) {
					setNotifications = false
				}
			}

			// If status is not yet determined, continue
			if (setNotifications == null) {
				let data = JSON.parse(this.response);
				let routes = data.routes;
				if (routes.length > 0) {
					route = routes[0];
					let commuteTime = route["legs"][0][args.transportation === "driving" ? "duration_in_traffic" : "duration"]["value"];
					var eventTime = null;
					if (args.daily) {
						eventTime = new Date()
							.setHours(new Date(args.eventTime).getHours(), new Date(args.eventTime).getMinutes(), new Date(args.eventTime).getSeconds());
					} else {
						eventTime = args.eventTime
					}
					if ((eventTime - commuteTime <= departureTime) && !(eventTime <= departureTime)) {
						setNotifications = true;
						notificationsTime = 0;
					} else if (!(eventTime <= departureTime)) {
						setNotifications = true;
						notificationsTime = eventTime - commuteTime - departureTime
					} else {
						setNotifications = false
					}
				} else {
					setNotifications = false;
				}
			}

			// If alarm is not daily, kill checking interval when setting notification
			if (setNotifications) {
				if (!args.daily) {
					clearInterval(intervalId)
				}
				// Overwrite currently set alarm
				clearTimeout(currentAlarmTimeout);
				currentAlarmTimeout = setTimeout( function () {
					// Send notifications for each repeat 30 seconds apart
					var repeats = args.repeats;
					var notificationIntervalId = null;
					notificationIntervalId = setInterval( function () {
						if (repeats > 0) {
							admin.messaging().sendToTopic(topic, payload)
								.then(function (response) {
									console.log("Successfully sent reminder:", response);
									})
								.catch(function (error) {
									console.log("Error sending message:", error);
									});
						} else {
							clearInterval(notificationIntervalId)
						}
						repeats++
					}, 1000 * 30);
					// store notification interval in alarm id
					admin.database().ref('/'+args.token+'/'+args.id+'/notification_interval').push(intervalId);
					}, 1000 * notificationsTime);
				admin.database().ref('/'+args.token+'/'+args.id+'/notification_timeout').push(currentAlarmTimeout);
			}
		};
		request.send();
	}, 1000 * 300);

	// store checking interval id in alarm id
	admin.database().ref('/'+args.token+'/'+args.id+'/checking_interval').push(intervalId);
});

exports.clearReminders = functions.https.onCall((id, token, context) => {
	const args = {
		id: id,
		token: token
	};

	// clear checking interval from id and erase from database
	admin.database.ref('/'+args.token+'/'+args.id+'/checking_interval').once('value', (snapshot) => {
		clearInterval(snapshot.val());
		admin.database.ref('/'+args.token+'/'+args.id+'/checking_interval').push(null)
	});

	// clear any set notification from id and erase from database
	admin.database.ref('/'+args.token+'/'+args.id+'/notification_timeout').once('value', (snapshot) => {
		clearTimeout(snapshot.val());
		admin.database().ref('/'+args.token+'/'+args.id+'/notification_timeout').push(null);
	});

	// clear notification interval from id and erase from database
	admin.database.ref('/'+args.token+'/'+args.id+'/notification_interval').once('value', (snapshot) => {
		clearInterval(snapshot.val());
		admin.database.ref('/'+args.token+'/'+args.id+'/notification_interval').push(null)
	});
});

exports.viewedNotification = functions.https.onCall((id, token, context) => {
	const args = {
		id: id,
		token: token
	};

	//clear notification interval from id and erase from database
	admin.database.ref('/'+args.token+'/'+args.id+'/notification_interval').once('value', (snapshot) => {
		clearInterval(snapshot.val());
		admin.database.ref('/'+args.token+'/'+args.id+'/notification_interval').push(null)
	});
});