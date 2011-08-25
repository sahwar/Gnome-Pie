/* 
Copyright (c) 2011 by Simon Schneegans

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>. 
*/

namespace GnomePie {

// A base class for actions, which are executed when the user
// activates a pie's slice.

public abstract class Action : GLib.Object {

    public abstract string action_type { get; }
    public abstract string label { get; }
    public abstract string command { get; }

    public virtual string name {get; protected set;}
    public virtual string icon_name {get; protected set;}
    public virtual bool is_quick_action {get; protected set;}

    public Action(string name, string icon_name, bool is_quick_action) {
        this.name = name;
        this.icon_name = icon_name;
        this.is_quick_action = is_quick_action;
    }

    public abstract void activate();
    
    public virtual void on_display() {}
    public virtual void on_remove() {}
    
    
    public static Action? new_for_uri(string uri, string? name = null) {
        var file = GLib.File.new_for_uri(uri);
        var scheme = file.get_uri_scheme();
        
        string final_icon = "";
        string final_name = file.get_basename();

        switch (scheme) {
            case "application":
                var file_name = uri.split("//")[1];
                
                var desktop_file = GLib.File.new_for_path("/usr/share/applications/" + file_name);
                if (desktop_file.query_exists())
                    return new_for_desktop_file(desktop_file.get_path());

                break;
                
            case "file":
                try {
                    var info = file.query_info("*", GLib.FileQueryInfoFlags.NONE);
                    
                    if (info.get_content_type() == "application/x-desktop")
                        return new_for_desktop_file(file.get_parse_name());
                    
                    var gicon = info.get_icon();
                                        
                    string[] icons = gicon.to_string().split(" ");
                    
                    foreach (var icon in icons) {
                        if (Gtk.IconTheme.get_default().has_icon(icon)) {
                            final_icon = icon;
                            break;
                        }
                    }
                    
                } catch (GLib.Error e) {
                    warning(e.message);
                }

                break;
                
            case "trash":
                final_icon = "user-trash";
                final_name = _("Trash");
                break;
                
            case "http": case "https":
                final_icon = "www";
                break;
                
            case "ftp": case "sftp":
                final_icon = "folder-remote";
                break;
        }
        
        if (!Gtk.IconTheme.get_default().has_icon(final_icon))
                final_icon = "application-default-icon";
        
        if (name != null)
            final_name = name;
        
        return new UriAction(final_name, final_icon, uri);
    }
    
    public static Action? new_for_desktop_file(string file_name) {
        var file = new DesktopAppInfo.from_filename(file_name);
        
        string[] icons = file.get_icon().to_string().split(" ");
        string final_icon = "application-default-icon";
                  
        foreach (var icon in icons) {
            if (Gtk.IconTheme.get_default().has_icon(icon)) {
                final_icon = icon;
                break;
            }
        }
        
        return new AppAction(file.get_display_name() , final_icon, file.get_commandline());
    }
}

}
