{{div}:DOM, create-class, create-factory} = require \react
{render} = require \react-dom
require! \react-router
Link = create-factory react-router.Link
Route = create-factory react-router.Route
Router = create-factory react-router.Router
pipe-storyboard = require \../../src/index
Layout = create-factory pipe-storyboard.Layout
Story = create-factory pipe-storyboard.Story
Storyboard = create-factory pipe-storyboard.Storyboard
{update-querystring} = require \./utils.ls

App = create-class do 

    display-name: \App

    # render :: a -> ReactElement
    render: ->
        Storyboard do 
            cache: false
            url: \http://localhost:4081
            controls: 
                * name: \enabled
                  label: \Enabled
                  type: \checkbox
                  default-value: true
                  client-side: true

                * name: \conversions
                  label: \Conversions
                  type: \number
                  default-value: 0

                * name: \visitors
                  label: \Visitors
                  type: \number
                  default-value: 300
                  client-side: true
                
                * name: \minX
                  label: 'min x'
                  type: \number
                  default-value: 0.01
                  client-side: true

                * name: \test
                  label: 'test'
                  type: \text
                  client-side: true
                ...
            state: @props.location.query
            on-change: (new-state) ~> 
                react-router.hash-history.replace-state null, (update-querystring window.location.href, new-state)
            Layout do 
                style:
                    flex-direction: \column
                    width: \100%
                Story do 
                    branch-id: \pztAHkd
                    style:
                        border-bottom: '1px solid #ccc'
                        height: 400
                Layout do 
                    style:
                        border-bottom: '1px solid #ccc'
                        width: \100%
                    Story do 
                        branch-id: \pztAHkd
                        show-title: false
                        show-links: false
                        style:
                            border-right: '1px solid #ccc'
                            flex: 1
                    Story do
                        branch-id: \pztAHkd
                        style:
                            flex: 1

render do 
    Router do 
        history: react-router.hash-history
        Route path: \/, component: App
    document.get-element-by-id \mount-node