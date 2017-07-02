# UICollectionView-Demo

<!-- <img src="CollectionViewDemo/extras/video-full.gif" alt="CollectionView Demo"> -->
<video alt="CollectionView Demo" controls>
<source src="CollectionViewDemo/extras/video-full.mp4" type="video/mp4" />
Your browser does not support the HTML video tag
</video>

## Overview
This is an advanced UICollectionView demo featuring a custom list layout and flexible grid layout. It demonstrates a wide variety of basic through advanced iOS techniques through a visually rich photo browsing demo. This project is intended as a tech demo to demonstrate iOS development techniques.

## Features
- UICollectionView that seamlessly transitions between list and grid layout
- **RHGridCollectionView**, a reusable collection view that can do flexible grid layouts. Unlike UICollectionView, RHGridCollectionView maintains constant spacing between cells.
- **RHParallaxScroller**, a concise and reusable utility for adding parallax scrolling to list, grid, or other scrolling view
- Simulated client/server architecture that abstracts away image downloads, enabling detailed testing of various synchronization issues that can occur when downloading multiple images at once
- Performance optimized image caching to allow smooth scrolling through a gallery of full size (several megapixel) photos
- Various UI polish details:
  - Using NSAttributedString to outline text for increased legibility
  - Using animations to mask slight performance delays
  - Cross fading between images
  - Using separate placeholder images for cached vs uncached images
  - Custom UI feedback when tapping photos
  - Navigation and tool bars that compress on landscape orientation

## Grid + List Layout

### Problem
The core feature of this demo is arranging photos in a grid or list layout. iOS's **UICollectionView** widget is very helpful this task, but it needed some customization to get the results I wanted. To see why, let's look at what happens if we use a UICollectionView to show a grid of 148px x148px thumbnails on an iPhone 6S+:

<img width="414" height="736" src="CollectionViewDemo/extras/screenshot-collectionView.png" alt="UICollectionView layout"/>
<img width="736" height="414"src="CollectionViewDemo/extras/screenshot-collectionView2.png" alt="UICollectionView layout - landscape"/>

As you can see, UICollectionView's default behavior is to use flexible horizontal spacing between grid elements. I can't think of a reason why this would ever be the desired behavior. So:

### Solution
I made **RHGridCollectionView** instead of using UICollectionView directly. RHCollectionView is built on top of UICollectionView, but is specialized for making better grid layouts. Given the same 148px x 148px iPhone 6 layout, RHGridCollectionView uses flexible horizontal margins instead of flexible horizontal spacing:

<img width="414" height="736" src="CollectionViewDemo/extras/screenshot-grid-flexibleMargins.png" alt="RHGridCollectionView layout - flexible margins"/>

This is a good layout, but it's not perfect yet because we are not using all of our horizontal screen space. So RHGridCollectionView adds support for **flexible grid layouts**:

<img width="414" height="736" src="CollectionViewDemo/extras/screenshot-gridView.png" alt="grid layout"/>
<img width="736" height="414" src="CollectionViewDemo/extras/screenshot-gridView2.png" alt="grid layout - landscape"/>

With RHGridCollectionView, configuring this flexible layout requires just 3 lines of code, works on all devices, and automatically updates in response to screen orientation changes or any other content size changes. To maintain the square shape of each photo, RHGridCollectionView adds support to **preserve aspect ratios** when resizing cells. Without this option enabled, RHGridCollectionView would stretch cells horizontally but maintain a constant row height.

Finally, there is the matter of switching to a list layout. I implemented this by adding support for **fixed column layouts** to RHGridCollectionView. With fixed column layouts, cells are automatically sized to fit a fixed number of columns. To implement a list layout, I just configured a grid layout with one column and no horizontal margin:

<img width="414" height="736" src="CollectionViewDemo/extras/screenshot-list.png" alt="list layout"/>
<img width="736" height="414" src="CollectionViewDemo/extras/screenshot-list2.png" alt="list layout - landscape"/>

Because this list layout is just a special kind of grid layout in RHGridCollectionView, we can seamlessly transition between grid and list layouts, even in the middle of a scroll.


## Parallax 

This demo includes a subtle UI detail that makes a noticeable difference in the end result. While scrolling photos, the photo contents shift slightly to give a perception of depth. To illustrate, here is the parallax effect I use at double the usual intensity:

<img src="CollectionViewDemo/extras/video-parallax.gif" alt="parallax" />

This effect is from **RHParallaxScroller**, a simple utility with a single 15 line method that can implement this effect in lists / table views, grids / collection views, or any other scrolling view.


## Simulated Image Downloads + Multithreading

<img src="CollectionViewDemo/extras/video-loading.gif" alt="loading"/>

### Problem
By far the most challenging part of this project was scrolling quickly through a photo gallery while each photo potentially spawns an image download on a separate thread. On top of typical multithreading challenges, multithreading with a collectionView is especially tricky. Collection views recycle old cells, potentially in the middle of a download. So, for example, if you have completed an image download for a cell, it is possible that the cell has been recycled and is being used for a different photo by the time the download completes.

### Solution - Image Downloads
The key to getting to the bottom of threading issues for scrolling through a photo gallery was to create a custom **ImageDataProvider** component that simulates downloading an image from a server, but without actually downloading an image and with additional configuration options. When combined with UI controls for re-downloading all images or erasing all data at any time, we can stress test the app in ways that reliably generate threading complications. For example, erasing all data while in the middle of a scroll will likely crash your app unless its multithreading logic is airtight. Also, reloading repeatedly while setting a large variability in download times will likely cause UI bugs such as incorrect images. Although the code behind ImageDataProvider is still experimental, the concept behind ImageDataProvider is a proven one that I have used in other apps with great success. Simulating data downloads gives us much more control over testing our app logic and much higher confidence that our app will survive real world conditions. In the case of this demo, the key was to simulate slow image downloads with a large variability in download speed. In other apps or a future version of this demo, I might also use simulated data to generate errors for testing error handling, or to generate unusual data that is likely to cause bugs.

### Solution - Multithreading
When multiple image downloading threads need to access the same image data, we can run into a variety of subtle race conditions and intermittent bugs. The solution for typical multithreading issues in this project is simple - we only access or modify image data on the foreground thread. Background threads are only used for downloading images or generating a thumbnail from a file. This way, we don't need to solve race condition issues because we never run into them.

### Alternative - Cancelable Downloads
A tempting alternative solution to threading complications might have been to just cancel any pending image downloads as a photo scrolls off screen. I decided against this for a few reasons.
- Preserving image downloads improves the user experience. If scrolling past a photo and back, the photo would not be available if we canceled downloads
- In a real world setting it is unlikely that the existing client/server architecture was set up with cancelable requests in mind 
- I wanted the challenge of solving multiple concurrent image downloads for my own education


## Scrolling + Performance

<img src="CollectionViewDemo/extras/video-scrolling.gif" alt="scrolling"/>

To appreciate what you are seeing in the above animation, keep in mind that we are looking at a gallery of full size camera photos - about 4 million pixels each - and that fast scrolling is silky smooth with a minimal memory footprint. Also keep in mind that this scrolling is twice as smooth on a real device - making a screen recording drops the frame rate from 60 to 30 frames per second.

To get this level of performance required a few steps:

- Creating an efficient algorithm for cropping and resizing large images to only the size needed on screen. 
- Doing all image loading asynchronously on a background thread
- Preloading images before they are needed on the screen
- Using a black square as a placeholder image while loading images from disk

The key part was to make an efficient algorithm for creating a small image from a large photo file without loading the entire photo into memory.

Another important trick was to customize the UI treatment for loading an image from the disk cache instead of from a remote download. When loaded from disk, photos use a black square as a placeholder image while loading, then animate in the photo quickly. This is an example of one of my favorite tricks, which is to use animations to hide performance bottlenecks. This blank placeholder only shows up if you scroll very quickly, and is barely noticeable. Have you noticed it in the above animation? If you look very closely, you will see that some images are slightly darker as they scroll in from the far top of the screen. And if you still can't see the effect - that's exactly the point.

I use the same trick when autorotating or transitioning between list and grid views. The photo view fades to black, then a new view fades in. This is not just for visual flair, but to mask subtle split second delays from having to regenerate photos for a different size.

