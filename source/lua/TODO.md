
This list is for things that need to be completed for this mod, that don't have a spot to put the note yet.

Other todo items that need to be completed will have a `--TODO(author):` to start it.

- Setting File.
    - Use vanilla one, since that has access to Steam storage. 
    - Use our own node/folder, "MAV" so we can keep the vanilla one nice and neat. (unlike ns2+.. heh)
    - Store the identifier for the AV the client is currently using.
    - Store the user settings for each MAV-compatible AV mod in its own tree, using mod-specified identifier.
- Options Menu Implementation
    - GUIConfig generator for a set of parameters that can be set for the shader.
        - The only parameter type supported atm is "float", so this part should be easier than it sounds.
        - All need to be expandable, and only show it's respective contents when its shader is selected.
        - If an AV mod isn't available, show a "missing" icon. If the user loads up the game with a missing AV mod 
          selected, show a popup.
- MAV Multiple AV Mods Handling
    - Use a sub-folder to differentiate the different DarkVision files.
    - The sub-folder name will be the identifier for the AV mod itself, for use by MAV.
    - In each respective sub-folder, there will be another file called `interface.json`
        - This JSON file will contain all the information necessary for defining settings
          as well as any meta-data the author might want to include. (tooltip, tooltip images, title, description, etc)
- MAV Documentation
    - Make github wiki pages for this repo on how to implement a mod that is meant to work with MAV. 
        - Link it in-game somewhere as well as on the repro readme.
        - Make sure to document these things
            - How to structure the filesystem of the MAV addon.
            - How to implement a `interface.json` file
            
