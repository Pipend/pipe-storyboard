require! \moment
{map} = require \prelude-ls
{{div}:DOM, create-class, create-factory} = require \react
{render} = require \react-dom
require! \react-router
{hash-history} = react-router
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
    default-from-date = moment!.subtract 3, \month .format \YYYY-MM-DDTHH:mm
    from-date = @props.location.query?.from ? default-from-date

    default-to-date = moment!.format \YYYY-MM-DDTHH:mm
    to-date = @props.location.query?.to ? default-to-date

    Storyboard do 
      cache: false
      url: \http://ndemo.pipend.com
      controls: 
        * name: \from
          label: \From
          type: \datetime-local
          default-value: default-from-date

        * name: \to
          label: \To
          type: \datetime-local
          default-value: default-to-date

        * name: \searchString
          label: \search
          type: \text
          default-value: ""

        * name: \username
          label: \username
          type: \text
          default-value: ""

        * name: \channel
          label: \channel
          type: \text
          default-value: ""

        * name: \limit
          label: \limit
          type: \number
          default-value: 100

        * name: \show
          label: \show 
          type: \checkbox
          default-value: true
        ...
      state: @props.location.query
      on-change: (new-state) ~> 
        hash-history.replace (update-querystring window.location.href, new-state)
      Story query-id: \pAXNE4w

render do 
  Router do 
    history: hash-history
    Route path: \/, component: App
  document.get-element-by-id \mount-node