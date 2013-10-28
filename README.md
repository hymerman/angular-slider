angular-slider
==============

Slider directive implementation for AngularJS, without jQuery dependencies. Requires AngularJS v1.1.4 or higher (optional isolate scope bindings support).

#### Note from brianmcd: 
The code in the original repo doesn't work when the directive is used in a transcluded scope.
This is a hacked version that works by removing the usage of `compile` in the directive.
This only works with range sliders, since that's all I need.


### Example:

    <ul>
        <li ng-repeat="item in items">
            <p>Name: {{item.name}}</p>
            <p>Cost: {{item.cost}}</p> 
            <slider floor="100" ceiling="1000" step="50" precision="2" ng-model="item.cost"></slider>
        </li>
    </ul>

### Range:

    <ul>
        <li ng-repeat="position in positions">
            <p>Name: {{position.name}}</p>
            <p>Minimum Age: {{position.minAge}}</p> 
            <p>Maximum Age: {{position.maxAge}}</p> 
            <slider floor="10" ceiling="60" ng-model-low="position.minAge" ng-model-high="position.maxAge"></slider>
        </li>
    </ul>

### Formatting:

Raw data can be formatted as text using the _translate_ attribute.
In your controller:

    $scope.currencyFormatting = function(value) { return value.toString() + " $" }

And your HTML:

    <slider floor="100" ceiling="1000" step="50" precision="2" ng-model="item.cost" translate="currencyFormatting"></slider>
    
### Usage:

Make sure to load AngularJS first, and then `angular-slider.js`. Also include the related `angular-slider.css`.

The module is named `uiSlider`. To enable it, you must simply list it as a dependency in your app. Example:

    var app = angular.module('app', ['uiSlider', 'ngResource', ...]);
    
You can then use it in your templates like so:

    <html ng-app='app'>
        ...
        <body>
            ...
            <slider ...></slider>
        </body>
    </html>


### Known issues:
  
1. When applying filters or orders within an ng-repeat directive, the element can abruptly change its position when the value attached to the slider causes a filter to activate or the order to change. 
Example: In the above snippet, it would be a very bad idea to order the list by item.cost.

### Roadmap:

1. ~~Touch events support~~
2. Smooth curve heterogeneity
3. Filters support

### License: MIT
