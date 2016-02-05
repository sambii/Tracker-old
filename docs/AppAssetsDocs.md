# Application Asset Pipeline Documentation

## Structure of the Asset Pipeline
The asset pipeline has been kept in the Rails default structure.  Thus all javascripts are found within the app/assets/javascripts directory, and all stylesheets are found within the app/asset/stylesheets directory.

Because we are delivering fonts down to the client, we now also have an app/assets/fonts folder. See config/application.rb for customization code.

To keep the vendor assets organized, the vendor/assets/javascripts, vendor/assets/stylesheets and vendor/assets/fonts directories are organized by product or vendor.

To not get confused about versions of vendor code, each vendor asset folder is versioned.  To update a version, add the new version into the vendor/assets/.../ folder and change the application.js or application.css.sass files to pull in the updated version.

## ProUI Specific adjustments

### Summary of what items from ProUI have been split out in the Asset Pipeline
The following items were separated out from ProUI when placed in the Asset Pipeline:
* jquery - the javascript was removed from ProUI and the matching non-minified version is in the vendor/assets/javascripts folder.
* bootstrap - the css for bootstrap is the css from ProUI, but the non-minified version is in the vendor/assets/javascripts folder.
* fontawesome - has been removed from ProUI and placed in the vendor/assets/fonts folder.
* glyphicons - has been removed from ProUI and not replaced.

### LESS 
In order to be able to extend any of the ProUI or Bootstrap styling, we used the original LESS files from Bootstrap and from ProUI.  This allows us to be able to override any ProUI or Bootstrap LESS code, without having to change every place the LESS code got compiled to.

The 'less-rails' gem was used to compile the LESS code in the Asset Pipeline.

### Fonts
Fonts were set up to work with the asset pipeline. The config/application.rb file was modified so that Fonts were added to the Asset Pipeline path, and fonts were precompiled.

It was decided that we were going to keep the Font Awesome font, but remove the Glyphicons pro.  Font Awesome was sufficient for our needs, and the Glyphicons license would be a problem for distribution.

Although we are using the Font Awesome font, the Font Awesome from the ProUI package was separated out in the asset pipeline.  This was done for several reasons.  First, to properly specify the file location in the LESS/CSS code using the asset pipeline, we needed to specify it by the font-url method instead of the url location.  Secondly, this separation will allow us to easily update the fonts in the future, and take advantage of any new characters provided.

Our license for do not allow us to distribute our code with Glyphicons without negotiating for the use of the Glyphicons Pro license.  The removal of the Glyphicons was done in preparation for possible distribution in the future.  The font files were removed and the references in LESS/CSS were removed as well.

##Files adjusted
* the proui version of bootstrap.less was modified to not pull in glyphicons.
* styles.less - removed the glyphicons and fontawesome less files (lines 26-27)
* font-awesome.less and glyphicons.less were removed
* the font awesome folder was added to the vendor/assets/fonts folder
* the font awesome css was added to the stylesheets directory, and changed to an erb to use the font-url method to properly call in the fonts from the asset pipeline.
* vendor/assets/stylesheets/proui-v2.0/variables.less - modified line 79: @assets_folder: '../proui-v2.0';
* vendor/assets/javascripts/proui-v2.0/app.js - added a call to window.trackerCommonCode.resizePageContent() in the resizePageContent routine, to isolate all of our custom resize code into our trackerCommonCode module.  Note: left animation speed (upspeed and downspeed) at 250ms (1/4 second)

### jQuery
jQuery - jquery was removed from the javascripts vendor folder, and the non-minified version is available so that when in development mode, the code will be readable when debugging.  Normally the version of jquery is not specified because it comes automatically with Rails.  In order to have the specific version of jquery that is known to work with ProUI, it was added to the vendor/assets/javascripts folder.

### Bootstrap
Bootstrap is pretty much the Bootstrap that is provided with ProUI.  The LESS version of the LESS/CSS code that came with ProUI has been kept there (it has the components needed for ProUI).  The javascript file for bootstrap was removed, and replaced with a matching version that is not minified in the vendor/assets/javascripts folder.

### ProUI Themes
The license for ProUI allows us to use and distribute one theme, but we are going to only use the default theme, and customize it as we see fit.  All themes have been removed in preparation for future distribution.

## ProUI/Bootstrap plugin addition or removal
Before going to production, all bootstrap or proui plugins that are not needed should be removed from the asset pipeline to speed up the page load.  The files that should be modified to do this are:
* proui app.js
* proui plugins.js
* bootstrap.js
* appropriate files from the stylesheets plugins directory
* styles.less

## ProUI specific adjustments to be made when going Open Sourced or distributed per the license agreement
* The ProUI themes have alreasy been removed.
* The Glyphicons fonts have already been removed.
* The ProUI license must be placed in all appropriate places, per the ProUI License Agreement.
* The ProUI LESS/CSS will need to be minimized.  Details of this need to be worked out (can LESS be minimized? Will we need to precompile all the LESS code, including our ProUI customizations?)


## Extras

--------------------------------------------
### letter to John at ProUI
John,

 I am writing this email to you, so that you might better understand how I am dealing with my assets, and that there is a way for you to provide the javascript, LESS and other items, that will be simplest for both of us.

I noticed that the mockup came with a application.css that contains all the CSS for 
Font Awesome, Bootstrap , and other`s.  In these files, are some hard coded directory structures that are problematic for me. 

I am trying to develop a simple process for updating these files in the future, and at the same time work with the Rails way of doing things.  The standard Rails Asset Pipeline wants to have fonts, images, javascripts and CSS into separate base directories.  At the same time, I wanted to use the original vendor files for easy version identification and updating, as well as being able to take advantage of the original vendor's LESS code.​

There is particular reason that I have split out the jquery code.  This is because rails has a standard version(s) of jquery and jquery-ui, so I making sure that I can (if necessary) specify which jquery and jquery-ui that I am using.  So far the jquery from proui (1.11.1) is ok

Fonts need to be in their own directory, so I have split out the Font Awesome CSS to properly point to that directory.

In the Javascript directory, I have basically split out Bootstrap, Jquery from Proui, so that I can document and possibly update versions.

In the CSS directories, I basically separated out the font-awesome, and then used the custom LESS files from ProUI for bootstrap, proui and other plugins.

My hopes is that when you send me the LESS files, it will all work nicely.

I know that if/when we open source this, that certain files will need to be minimized.  Is it possible that when we are done, that you could provide us with minimized versions of the files that need to be minimized (or some instructions to do that and which files need to be minimized).  I am hoping that we could also have non-minimized versions for our in-house debugging purposes.


thanks,
Dave


If you are interested this is my assets directory layout:

fonts
--font-awesome-4.1.0
images (still ironing out urls for these)
-- proui-v2.0 (I will bump this up)
----jquery.chosen
----jquery.datatables
----jquery.select2
----placeholders
----template
javascripts
-- bootstrap-v3.1.1
-- jquery-1.11.1
-- proui-v2.0 (I will bump this up)
----ckeditor
----helpers
----pages
----vendor
------modernizr-2.7.1.....
stylesheets
-- font-awesome-4.1.0 (custom coded CSS file)
--proui-v2.0 (will bump this up)
----bootstrap (customized LESS files from proui)
----main (LESS files from proui)
----plugins (customized LESS files from proui)


Dave Taylor

--------------------------------------------
### response letter from John at ProUI

Hi Dave, thanks for letting me know about your setup :-)

I will send you the final HTML page tomorrow along with an additional Javascript and LessCSS file. You won't have to worry about the lines which include CSS & Javascript files in the page, they just follow the default ProUI structure, so you could test the page directly in the ProUI release if you like.

I suppose you have created a template ProUI page for the project, based on your new file structure. As long as you load all the CSS & JS required files, you only have to:
Get the content from inside the <body> of the HTML page and add it to your custom template page (without the JS included files and JS code at the bottom)
Include the additional JS file in this page after all other JS files
Include the additional LessCSS file after all other files
Everything should work nicely without any issues but if something comes up, let me know :-)

To answer your last question about the minimized files, of course, you can have the original un-minimized versions for your in-house development and debugging purposes. The only files that would have to be minimized in the open source code are the main/* LessCSS files. Should you need any further info or assistance about the terms we have signed before releasing as Open Source, please let me know.

Best Regards,

John

--------------------------------------------

