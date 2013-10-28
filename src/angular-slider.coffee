# CONSTANTS

MODULE_NAME = 'uiSlider'
SLIDER_TAG  = 'slider'

# HELPER FUNCTIONS

angularize      = (element) -> angular.element element
pixelize        = (position) -> "#{position}px"
hide            = (element) -> element.css opacity: 0
show            = (element) -> element.css opacity: 1
offset          = (element, position) -> element.css left: position
halfWidth       = (element) -> element[0].offsetWidth / 2
offsetLeft      = (element) -> element[0].offsetLeft
width           = (element) -> element[0].offsetWidth
gap             = (element1, element2) -> offsetLeft(element2) - offsetLeft(element1) - width(element1)
roundStep       = (value, precision, step, floor = 0) ->
    step ?= 1 / Math.pow(10, precision)
    remainder = (value - floor) % step
    steppedValue =
        if remainder > (step / 2)
        then value + step - remainder
        else value - remainder
    decimals = Math.pow 10, precision
    roundedValue = steppedValue * decimals / decimals
    roundedValue.toFixed precision
inputEvents =
    mouse:
        start: 'mousedown'
        move:  'mousemove'
        end:   'mouseup'
    touch:
        start: 'touchstart'
        move:  'touchmove'
        end:   'touchend'

# DIRECTIVE DEFINITION

sliderDirective = ($timeout) ->
    restrict: 'EA'
    scope:
        floor:       '@'
        ceiling:     '@'
        step:        '@'
        precision:   '@'
        translate:   '&'
        ngModel:     '=?'
        ngModelLow:  '=?'
        ngModelHigh: '=?'
    template: '<span class="bar"></span>
               <span class="bar selection"></span>
               <span class="pointer"></span>
               <span class="pointer"></span>
               <span class="bubble selection">Range: {{ translate({value: diff}) }}</span>
               <span class="bubble limit">{{ translate({value: floor}) }}</span>
               <span class="bubble limit">{{ translate({value: ceiling}) }}</span>
               <span class="bubble">{{ translate({value: ngModelLow}) }}</span>
               <span class="bubble">{{ translate({value: ngModelHigh}) }}</span>
               <span class="bubble">{{ translate({value: ngModelLow}) }} - {{ translate({value: ngModelHigh}) }}</span>'
    link: (scope, element, attributes) ->

        # This has been hacked to only work with ranges.
        # This was done to get rid of the compile function, which is causing issues
        # when this directive is used in a transcluded scope.
        range = true

        # Get references to template elements
        [fullBar, selBar, minPtr, maxPtr, selBub,
            flrBub, ceilBub, lowBub, highBub, cmbBub] = (angularize(e) for e in element.children())
        
        # Scope values to watch for changes
        watchables = ['ngModelLow', 'floor', 'ceiling', 'ngModelHigh']

        boundToInputs = false
        ngDocument = angularize document
        unless attributes.translate
            scope.translate = (value) -> value.value

        pointerHalfWidth = barWidth = minOffset = maxOffset = minValue = maxValue = valueRange = offsetRange = undefined

        dimensions = ->
            # roundStep the initial score values
            scope.precision ?= 0
            scope.step ?= 1
            scope[value] = parseInt(roundStep(parseFloat(scope[value]), parseInt(scope.precision), parseFloat(scope.step), parseFloat(scope.floor)), 10) for value in watchables
            scope.diff = roundStep(scope.ngModelHigh - scope.ngModelLow, parseInt(scope.precision), parseFloat(scope.step), parseFloat(scope.floor))
            
            # Commonly used measurements
            pointerHalfWidth = halfWidth minPtr
            barWidth = width fullBar

            minOffset = 0
            maxOffset = barWidth - width(minPtr)

            minValue = parseFloat attributes.floor
            maxValue = parseFloat attributes.ceiling

            valueRange = maxValue - minValue
            offsetRange = maxOffset - minOffset

        updateDOM = ->
            dimensions()

            # Translation functions
            percentOffset = (offset) -> ((offset - minOffset) / offsetRange) * 100
            percentValue = (value) -> ((value - minValue) / valueRange) * 100
            percentToOffset = (percent) -> pixelize percent * offsetRange / 100

            # Fit bubble to bar width
            fitToBar = (element) -> offset element, pixelize(Math.min (Math.max 0, offsetLeft(element)), (barWidth - width(element)))

            setPointers = ->
                offset ceilBub, pixelize(barWidth - width(ceilBub))
                newLowValue = percentValue scope.ngModelLow
                offset minPtr, percentToOffset newLowValue
                offset lowBub, pixelize(offsetLeft(minPtr) - (halfWidth lowBub) + pointerHalfWidth)

                newHighValue = percentValue scope.ngModelHigh
                offset maxPtr, percentToOffset newHighValue
                offset highBub, pixelize(offsetLeft(maxPtr) - (halfWidth highBub) + pointerHalfWidth)
                offset selBar, pixelize(offsetLeft(minPtr) + pointerHalfWidth)
                selBar.css width: percentToOffset newHighValue - newLowValue
                offset selBub, pixelize(offsetLeft(selBar) + halfWidth(selBar) - halfWidth(selBub))
                offset cmbBub, pixelize(offsetLeft(selBar) + halfWidth(selBar) - halfWidth(cmbBub))

            adjustBubbles = ->
                fitToBar lowBub
                bubToAdjust = highBub

                fitToBar highBub
                fitToBar selBub

                if gap(lowBub, highBub) < 10
                    hide lowBub
                    hide highBub
                    fitToBar cmbBub
                    show cmbBub
                    bubToAdjust = cmbBub
                else
                    show lowBub
                    show highBub
                    hide cmbBub
                    bubToAdjust = highBub

                if gap(flrBub, lowBub) < 5
                    hide flrBub
                else
                    if gap(flrBub, bubToAdjust) < 5 then hide flrBub else show flrBub

                if gap(lowBub, ceilBub) < 5
                    hide ceilBub
                else
                  if gap(bubToAdjust, ceilBub) < 5 then hide ceilBub else show ceilBub


            bindToInputEvents = (pointer, ref, events) ->
                onEnd = ->
                    pointer.removeClass 'active'
                    ngDocument.unbind events.move
                    ngDocument.unbind events.end
                onMove = (event) ->
                    eventX = event.clientX || event.touches[0].clientX
                    newOffset = eventX - element[0].getBoundingClientRect().left - pointerHalfWidth
                    newOffset = Math.max(Math.min(newOffset, maxOffset), minOffset)
                    newPercent = percentOffset newOffset
                    newValue = minValue + (valueRange * newPercent / 100.0)
                    if range
                        if ref is 'ngModelLow'
                            if newValue > scope.ngModelHigh
                                ref = 'ngModelHigh'
                                minPtr.removeClass 'active'
                                maxPtr.addClass 'active'
                        else
                            if newValue < scope.ngModelLow
                                ref = 'ngModelLow'
                                maxPtr.removeClass 'active'
                                minPtr.addClass 'active'
                    newValue = roundStep(newValue, parseInt(scope.precision), parseFloat(scope.step), parseFloat(scope.floor))
                    scope[ref] = parseInt(newValue, 10)
                    scope.$apply()
                onStart = (event) ->
                    pointer.addClass 'active'
                    dimensions()
                    event.stopPropagation()
                    event.preventDefault()
                    ngDocument.bind events.move, onMove
                    ngDocument.bind events.end, onEnd
                pointer.bind events.start, onStart

            setBindings = ->
                boundToInputs = true
                bind = (method) ->
                    bindToInputEvents minPtr, 'ngModelLow', inputEvents[method]
                    bindToInputEvents maxPtr, 'ngModelHigh', inputEvents[method]
                bind(inputMethod) for inputMethod in ['touch', 'mouse']

            setPointers()
            adjustBubbles()
            setBindings() unless boundToInputs

        $timeout updateDOM
        scope.$watch w, updateDOM for w in watchables
        window.addEventListener "resize", updateDOM

qualifiedDirectiveDefinition = [
    '$timeout'
    sliderDirective
]

module = (window, angular) ->
    angular
        .module(MODULE_NAME, [])
        .directive(SLIDER_TAG, qualifiedDirectiveDefinition)

module window, window.angular
