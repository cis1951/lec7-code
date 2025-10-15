# Guesstaurant
This repo contains the starter code for **Lecture 7: Sensors**.

> [!IMPORTANT]
> If this project fails to run, **change the bundle identifier** in the project settings to something unique. An easy way to do this is to add some random digits to the end of the current bundle identifier.
> 
> To edit the bundle identifier, go to your project settings (the topmost "Guesstaurant" item on the sidebar), choose the "Guesstaurant" target, and click the "General" tab. You should see a "Bundle Identifier" field there.

Today, we're going to build a game using location and motion data! In this game, you'll place your phone on your forehead and try to guess the name of the restaurant that's displayed on the screen, using only hints that your friends give you. You'll learn to use location data to find restaurants near you, then motion data to control the game.

Here's a walkthrough of the steps you'll take to build out the starter code into a full game:

## Step 1: Set up a `CLLocationManager`

Everything starts from somewhere, and for location data, that somewhere is `CLLocationManager`. You'll eventually use this class to request permission and get the user's location, but we'll start off by just creating it as part of the `GameViewModel` class. Go ahead and add this property to `GameViewModel`:

```swift
let locationManager = CLLocationManager()
```

Next, we'll need to register the `GameViewModel` as the delegate for the `CLLocationManager`, so we can actually receive the user's location once it's ready. To do this, we'll need to update our class declaration, like this:

```swift
@Observable class GameViewModel: NSObject, CLLocationManagerDelegate
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
2. Request permission to access the user's location with `locationManager.requestWhenInUseAuthorization()`. This method won't do anything if the user has already made their choice, so it's safe to call regardless of the current authorization status.

<details>
<summary>Solution (don't look at this unless you're stuck!)</summary>

```swift
func loadGame() {
    state = .loading
    locationManager.requestWhenInUseAuthorization()
}
```

Note that your solution doesn't have to match exactly.
</details>

There's one more thing we have to do: adding a purpose string. To do that on a more recent version of Xcode:
1. Navigate to your project settings (the topmost "Guesstaurant" item on the sidebar).
2. Choose the "Guesstaurant" target
3. Click the "Signing & Capabilities" tab.
4. Click the "+ Capability" button, and add the **Location (When In Use)** property.
5. Enter a purpose string in the field that appears.

If that doesn't work, you may need to instead do the following:
1. Navigate to your project settings (the topmost "Guesstaurant" item on the sidebar).
2. Choose the "Guesstaurant" target
3. Click the "Info" tab.
4. Under "Custom iOS Target Properties", add a row with the key `NSLocationWhenInUseUsageDescription`. Xcode may format it as **Privacy - Location When In Use Usage Description**.
5. Set the type to "String", then enter your purpose string in the value field.

You can now run the app -- it should prompt you for location access when it starts!

> [!NOTE]
> Typically, you *don't* want to request location access until you've had a chance to explain to the user why you need it. This is called [permission priming](https://www.useronboard.com/onboarding-ux-patterns/permission-priming/), and you should learn it if you're developing a production app.

## Step 3: Respond to the user's choice

If we had to request location access in step 2, we won't immediately know whether the user chose to grant or deny it. Instead, CoreLocation will call our `locationManagerDidChangeAuthorization` method, and we'll be able to check the user's choice there. Go ahead and implement it with this logic:
1. If the user granted access, request their location with `locationManager.requestLocation()`.
2. If the user *denied* access, set the game's state to `.error`, which will show an error message in `GameView`. (Optionally, you can log a message to the console for debugging purposes.)
3. If neither are true, do nothing.

You may want to reference the [CLLocationManager docs](https://developer.apple.com/documentation/corelocation/cllocationmanager).

> [!TIP]
> If you start typing `func locationManagerDidChangeAuthorization` in the body of `GameViewModel`, Xcode will offer to autocomplete the method - complete with arguments - for you!

Note that the system will always call `locationManagerDidChangeAuthorization` the moment we create the `CLLocationManager`, so we don't need to request the user's location elsewhere in the code. Once this is done, the app will now request the user's location as soon as access is granted!

<details>
<summary>Solution (don't look at this unless you're stuck!)</summary>

```swift
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
        locationManager.requestLocation()
    case .denied, .restricted:
        state = .error
    default:
        break
    }
}
```
</details>

## Step 4: Search for restaurants with the user's location

We've asked permission and requested the user's location - now it's time to use it!

It can take some time for `CLLocationManager` to get the user's location - once it's done, it will call either `locationManager(_:didUpdateLocations:)` or `locationManager(_:didFailWithError:)`. Let's start with a simple error handler for the latter:

```swift
func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Failed to get location: \(error)")
    state = .error
```

Now, implement `locationManager(_:didUpdateLocations:)`, which should:
1. Get the last location in the array.
2. Construct a `MKLocalSearch` object using the location's `coordinate`, and configure it so that it searches for restaurants.
    * [MKLocalSearch](https://developer.apple.com/documentation/mapkit/mklocalsearch) comes from MapKit, the Apple Maps API. To make one, you'll need either a [MKLocalSearch.Request](https://developer.apple.com/documentation/mapkit/mklocalsearch/request) or a [MKLocalPointsOfInterestRequest](https://developer.apple.com/documentation/mapkit/mklocalpointsofinterestrequest).
3. Call the `fetchPlaces` method with the `MKLocalSearch` object. (We've already implemented `fetchPlaces` for you.)

<details>
<summary>Solution (don't look at this unless you're stuck!)</summary>

```swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.last {        
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 2000)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .foodMarket, .bakery, .cafe])
        
        let search = MKLocalSearch(request: request)
        fetchPlaces(search: search)
    }
}
```

> [!NOTE]
> The **guard** statement checks that its condition is true before allowing execution to continue. If the condition is false, it will return early.
</details>

When it's done, `fetchPlaces` will populate the `restaurants` array and call `startGame()`. We'll flesh out `startGame()` later, but for now, have `startGame()` display a random restaurant:

```swift
func startGame() {
    if let restaurant = restaurants.randomElement() {
        state = .restaurant(restaurant)
    } else {
        print("List of restaurants is empty!")
        state = .error
    }
}
```

Now, run your app - once it's done loading, you should see a restaurant name on the screen!

## Step 5: Set up motion sensing

It's time to add motion to our game! Much like `CLLocationManager`, we'll start by setting up a `CMMotionManager`. Add this property to your `GameViewModel`:

```swift
let motionManager = CMMotionManager()
```

Now, we can rewrite `startGame()` to start listening for motion data. We'll also have it display error messages and stop the game if something goes wrong:

```swift
func startGame() {
    if motionManager.isDeviceMotionAvailable {
        state = .ready

        motionManager.deviceMotionUpdateInterval = 1 / 60
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let self {
                if let motion {
                    handleMotion(motion)
                } else if let error {
                    print("Failed to receive motion update: \(error)")
                    state = .error
                    motionManager.stopDeviceMotionUpdates()
                }
            }
        }
    } else {
        print("Device motion is not available!")
        state = .error
    }
}
```

Now, roughly 60 times per second, the system will call our `startDeviceMotionUpdates` handler with updated motion data, which in turn will call our game model's `handleMotion` method.

## Step 6: Control the game with motion data

Now for the fun part: implementing the game's logic! We've provided some stub code in `handleMotion` already, but it's up to you to fill it out. Here's a rough outline of what you'll need to do:
* If the game is in the **restaurant** state, we should check the motion data to see if the user is tilting their head up or down. If they are, we should change the game's state to **correct** or **skip** accordingly.
    * If you're setting the state to **correct**, you should also increment the user's score.
* If the game is in the **ready**, **correct**, or **skip** states, we should check the motion data to see if the user has returned their head to a neutral position. If they have, we should pick a random restaurant, then change the game's state to **restaurant**, much like we did at the end of step 4.
* For any other states, you can just do nothing (i.e. `break` if you're in a `switch`).

<details>
<summary>Hint</summary>

Because the device will be in the landscape position, we'll need to use the device's **roll**. Moreover, since we don't know which direction the device is facing, we'll need to take the absolute value of the **roll**, then compare it to some thresholds to determine whether the user is tilting their head up or down. Here's some code that might help:

```swift
let correctThreshold = Double.pi * 0.35
let skipThreshold = Double.pi * 0.65
let absoluteRoll = abs(motion.attitude.roll)
```
</details>

<details>
<summary>Solution (don't look at this unless you're stuck!)</summary>

```swift
let correctThreshold = Double.pi * 0.35
let skipThreshold = Double.pi * 0.65
let absoluteRoll = abs(motion.attitude.roll)

switch state {
case .ready, .correct, .skip:
    if (correctThreshold...skipThreshold).contains(absoluteRoll) {
        if let restaurant = restaurants.randomElement() {
            state = .restaurant(restaurant)
        } else {
            print("List of restaurants is empty!")
            state = .error
        }
    }
case .restaurant(_):
    if absoluteRoll < correctThreshold {
        state = .correct
        score += 1
    } else if absoluteRoll > incorrectThreshold {
        state = .skip
    }
default:
    break
}
```
</details>

And that's it! You've now built a game that uses location and motion data. Run your app on a physical device, and try playing it with your friends!

## Step 7: Going further

If you have time, try adding some of these features to your game:

* **Haptic feedback**: Vibrate the phone when the player guesses or skips a restaurant - this can dramatically improve the game's feel!
    * *Hint*: Use the [UIFeedbackGenerator](https://developer.apple.com/documentation/uikit/uifeedbackgenerator) class.
* **AirPods integration:** Use your AirPods' motion data to control the game, instead of the phone's. (This requires AirPods that support Spatial Audio.)
    * *Hint*: You should only need to edit one line and remove one line for this.
    * You will also need to add a `NSMotionUsageDescription` purpose string.
* **Debouncing:** The game might feel a bit sensitive, in that rapid head movement might cause a bunch of unwanted inputs. Try adding logic to ignore motion data for a short period after the player has made an input.
    * *Hint*: Keep track of when the player last made an input using a [Date](https://developer.apple.com/documentation/foundation/date) struct.