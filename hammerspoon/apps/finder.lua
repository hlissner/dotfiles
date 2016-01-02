
App.new("Finder")
   .onActivate(function(self, app)
     app:selectMenuItem({"Window", "Bring All to Front"})
   end)
