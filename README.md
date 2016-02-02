Pipe Storyboard
=================================

[![Build Status](https://travis-ci.org/Pipend/pipe-storyboard.svg?branch=master)](https://travis-ci.org/Pipend/pipe-storyboard)

Set of components to create storyboards from pipe queries

## Installation
`npm install pipe-storyboard`

## Usage
```LiveScript
pipe-storyboard = require \pipe-storyboard
Layout = create-factory pipe-storyboard.Layout
Story = create-factory pipe-storyboard.Story
Storyboard = create-factory pipe-storyboard.Storyboard

# used for creating custom componenets
LabelledComponent = create-factory pipe-storyboard.LabelledComponent

Storyboard do 

    # the pipe-server to get queries from
    url: \http://localhost:4081

    # a list of ui controls corresponding to the parameters of the child queries
    controls: 
        * name: \conversions
          label: \Conversions
          type: \number
          default-value: 0
          client-side: true
        ...

    # this tells the Storyboard component to load the ui-values from query-string
    state: @props.location.query

    # this function is invoked whenever a ui-value changes & updates the state
    on-change: (new-state) ~> 
        react-router.hash-history.replace-state null, (update-querystring window.location.href, new-state)

    # A layout component is used to position queries in a Storyboard
    Layout do 
        style: width: \100%

        # A Story component takes a query-id or branch-id and renders it
        # the values from the ui-controls (passed as controls prop above) will be mapped to parameters
        # and passed to each child query / layout
        Story branch-id: \pztAHkd
        Story branch-id: \pqucBWe
```

## Usage (css / stylus)
`@require 'node_modules/pipe-storyboard/src/index.css'`

## Components

* Storyboard

> Connects ui controls & queries by mapping ui values to parameters, and propagating these parameters to its children. Story, Layout or a Storyboard component itself can be passed as child. 
A Storyboard component also propagates the pipe api server url to its children, this can be overriden by setting the `url` prop on the child.

```LiveScript
Control :: {
    
    # name of the control, used for fetching and updating value from state
    name :: String 

    # optional parameter, enum of standard html input types, used internally to render the ui-control
    # if undefined the render method must be implemented
    type :: String 
    label :: String

    # optional parameter works in conjunction with type, for example, if type is text and placeholder is 'hello'
    # a html input element with type text and placeholder 'hello' will be rendered in the form
    placeholder :: String

    # optional parameter works in conjunction with the type value 'select'
    options :: [String]
    multi :: Boolean
    tether :: Boolean

    # the default ui value
    default-value :: a

    # optional parameter, false by default. 
    # A value of true implies that only the transformation and presentaiton function will be executed (no ajax request will be made),
    # whereas a value of false implies that an ajax request will be made to the pipe api server to re-execute the query before running the transformation & presentation functions
    client-side: true

    # optional parameter, specifies how to extract the value of the ui-control from the `State`
    # the `State` object is passed as a prop to the `Storyboard` component, 
    # default-implementation = (state) ~> state[name]
    ui-value-from-state :: State -> UIValue

    # optional parameter, specifies how to update the state using the new value of the ui-control
    # the result of this function is folded (with the result from other controls) to obtain the full `State` object
    # default implementation = (new-ui-value) ~> "#{name}" : new-ui-value
    state-from-ui-value :: UIValue -> State' 

    # optional parameter, specifies how to convert the ui-value into a parameter for the query
    # default implementation = (ui-value) ~> "#{name}" : ui-value
    # the result of this function is folded (with the result from other controls) to obtain the full `Parameters` object
    # example usage: converting between local and gmt timezones
    parameters-from-ui-value :: UIValue -> Parameters', where Parameters' :: Map Name, Value

    # optional parameter, allows you to provide a custom implementation for rendering the ui-control, 
    # the default implementation uses a combination of type, placeholder & options props
    render? :: UIValue -> (UIValue -> ()) -> ReactElement
}
```

|    Property                  |   Type                         |   Description                  |
|------------------------------|--------------------------------|--------------------------------|
|    cache                     | Boolean | Number               | pipe query cache parameter, propagated to children |
|    controls                  | [Control]                      |  |
|    extras                    | object                         | combines and propagates to Children |
|    state                     | State                          | an object that stores the state of the ui controls, this can be the state of the hosting component or the query string (for example) |
|    on-change                 | State -> ()                    | fired whenever the value of a ui-control changes, here you MUST update the state prop, above, to complete the data flow |
|    on-execute                | Parameters -> Boolean -> ()    | fired whenever the user executes either by clicking on search or using (ctrl + enter / command + enter) hotkeys |
|    on-reset                  | () -> ()                       | fired whenever the user resets the form, either by clicking or using (alt + r, option + r) hotkeys |
|    url                       | String                         | the url of the pipe api server, propagated to the children |

* Story 

> Renders a pipe query

|    Property                  |   Type                         |   Description                  |
|------------------------------|--------------------------------|--------------------------------|
|    cache                     | Boolean | Number               | pipe query cache parameter |
|    branch-id                 | String                         | the branch id of the pipe query, if specified the latest query for that branch will be rendered |
|    extras                    | object                         | extras are static parameters that are merged with the dynamic `Parameters` object, they help in reuse of queries |
|    query-id                  | String                         | the query id of the pipe query to be rendered |
|    url                       | String                         | the url of the pipe api server, usually propagated by the Storyboard component |
|    class-name                | String                         | custom class name for styling the component externally |
|    style                     | object                         | custom css styles useful in combination with Layout and flexbox |
|    title                     | String                         | title for the query, defaults to the query-title property of the pipe document |
|    show-title                | Boolean                        | defaults to true |
|    show-links                | Boolean                        | defaults to true (setting it to false will hide the links to edit, share, .. query/result) |

* Layout

|    Property                  |   Type                         |   Description                  |
|------------------------------|--------------------------------|--------------------------------|
|    cache                     | Boolean | Number               | pipe query cache parameter, propagated to children |
|    class-name                | String                         | custom class name for styling the component externally |
|    extras                    | object                         | combines and propagates to Children |
|    style                     | object                         | custom css styles |
|    url                       | String                         | the url of the pipe api server, usually propagated by the Storyboard component |