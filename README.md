# UICollectionView-Demo

## Overview
Advanced UICollectionView demo with custom list layout and flexible grid layout. Demonstrates a wide variety of basic through advanced iOS techniques with a visually rich photo browsing demo. This project is intended as a tech demo to demonstrate iOS development techniques.

## Features
- UICollectionView that seamlessly transitions between list and grid layout
- RHGridCollectionView, a reusable collection view that can do flexible grid layouts. Unlike UICollectionView, RHGridCollectionView maintains constant spacing between cells.
- RHParallaxScroller, a concise and reusable utility for adding parallax scrolling to any collection view, table view, or custom view
- Simulated client/server architecture that abstracts away image downloads. This allows for very detailed testing of various synchronization issues that can occur when scrolling collection views quickly while downloading images.
- Performance optimized image caching to allow smooth scrolling while viewing a gallery of full size (several megapixel) photos
- Various UI polish details:
  - Using NSAttributedString to outline text for increased legibility
  - Using animations to mask slight performance delays
  - Cross fading between images
  - Using separate placeholder images for cached vs uncached images
  - Custom UI feedback when tapping photos
  - Navigation and tool bars that compress on landscape orientation
