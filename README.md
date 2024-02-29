# Guesstaurant
This repo contains the starter code for **Lecture 7: Sensors**.

Today, we're going to build a game using location and motion data! In this game, you'll place your phone on your forehead and try to guess the name of the restaurant that's displayed on the screen, using only hints that your friends give you. You'll learn to use location data to find restaurants near you, then motion data to control the game.

Here's a walkthrough of the steps you'll take to build out the starter code into a full game:

## Step 1: Set up a `CLLocationManager`

Everything starts from somewhere, and for location data, that somewhere is `CLLocationManager`. You'll eventually use this class to request permission and get the user's location, but we'll start off by just creating it as part of the `GameViewModel` class. Go ahead and add this property to `GameViewModel`:

```swift
let locationManager = CLLocationManager()
```

Next, we'll need to register the `GameViewModel` as the delegate for the `CLLocationManager`, so we can actually receive the user's location once it's ready. To do this, we'll need to update our class declaration, like this:

```swift
class GameViewModel: NSObject, ObservableObject, CLLocationManagerDelegate
```

**What's that NSObject doing there?** `NSObject` was the base class for pretty much all objects back in the Objective-C era, similar to `Object` in Java. `CLLocationManagerDelegate` dates back from this era, and in order to conform to it, we'll need to make `GameViewModel` a subclass of `NSObject`.

Finally, we can set the delegate of the `locationManager`. Create a new initializer and do it there:

```swift
override init() {
    super.init()
    locationManager.delegate = self
}
```

(Note that this overrides `NSObject`'s initializer, which is why we need `override` and `super.init()` here.)

## Step 2: Request location permissions

Now, we're ready to ask the user to grant access to their location. We've created a stub method called `loadGame()`, which will be called when the game launches (or the user taps the Retry button on the error screen) -- there, you should:
1. Set the game's state to `.loading`, which will cause `GameView` to display a loading spinner.
2. Check if the user has already granted location permissions.
3. If they have (whether "always" or "when in use",) we're good to go! Request the user's location with `locationManager.requestLocation()`.
4. If they haven't, request permission with `locationManager.requestWhenInUseAuthorization()`.

You may want to reference the [CLLocationManager docs](https://developer.apple.com/documentation/corelocation/cllocationmanager).

<details>
<summary>Solution (don't look at this unless you're stuck!)</summary>

```swift
func loadGame() {
    state = .loading
    switch locationManager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
        locationManager.requestLocation()
    default:
        locationManager.requestWhenInUseAuthorization()
    }
}
```

Note that your solution doesn't have to match exactly.
</details>

You can now run the app -- it should prompt you for location access when it starts!

> [!NOTE]
> Typically, you *don't* want to request location access until you've had a chance to explain to the user why you need it. This is called [permission priming](https://www.useronboard.com/onboarding-ux-patterns/permission-priming/), and you should learn it if you're developing a production app.

## Step 3: Respond to the user's choice

If we had to request location access in step 2, we won't immediately know whether the user chose to grant or deny it. Instead, CoreLocation will call our `locationManagerDidChangeAuthorization` method, and we'll be able to check the user's choice there. Go ahead and implement it with this logic:
1. If the user granted access, request their location.
2. If the user *denied* access, set the game's state to `.error`, which will show an error message in `GameView`. (Optionally, you can log a message to the console for debugging purposes.)
3. If neither are true, do nothing.

There is, however, a small problem: the system will always call `locationManagerDidChangeAuthorization` the moment we create the `CLLocationManager`. This means that if the user has already granted location access, we might end up requesting the user's location *twice* simultaneously - once in `loadGame()`, and once in `locationManagerDidChangeAuthorization`. This is a waste of resources, as we only need to have one request active at a time. To avoid this:
* Move both `locationManager.requestLocation()` calls to a new method, and call that method in `loadGame()` and `locationManagerDidChangeAuthorization` instead.
* Add a new property to `GameViewModel` to track whether we're currently requesting the user's location.
* In your new method, only request the user's location if we're not already doing so.

Once this is done, the app will now request the user's location as soon as access is granted!

<details>
<summary>Solution (don't look at this unless you're stuck!)</summary>

```swift
var isRequestingLocation = false

func loadGame() {
    state = .loading
    switch locationManager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
        requestLocation()
    default:
        locationManager.requestWhenInUseAuthorization()
    }
}

func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
        requestLocation()
    case .denied, .restricted:
        state = .error
    default:
        break
    }
}

func requestLocation() {
    if !isRequestingLocation {
        isRequestingLocation = true
        locationManager.requestLocation()
    }
}
```

Note that your solution doesn't have to match exactly.

</details>