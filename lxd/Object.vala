/*
* Copyright (c) 2020 - Today Marco Betschart (https://marco.betschart.name)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Marco Betschart <boxes@marco.betschart.name>
*/

public abstract class LXD.Object : GLib.Object, Json.Serializable {

	public unowned ParamSpec? find_property (string name) {
		return ((ObjectClass) get_type ().class_ref ()).find_property (name);
	}

	public virtual Json.Node serialize_property (string property_name, Value @value, ParamSpec pspec) {
		if (@value.type ().is_a (typeof (GLib.Array))) {
			unowned GLib.Array<GLib.Object> array_value = @value as GLib.Array<GLib.Object>;

			if (array_value != null){
				var array = new Json.Array.sized (array_value.length);

				for(var i = 0; i < array_value.length; i++) {
					array.add_element (Json.gobject_serialize (array_value.index (i)));
				}

				var node = new Json.Node (Json.NodeType.ARRAY);
				node.set_array (array);
				return node;
			}
		}

		return default_serialize_property (property_name, @value, pspec);
	}

	public virtual bool deserialize_property (string property_name, out Value @value, ParamSpec pspec, Json.Node property_node) {

		if (pspec.value_type.is_a (typeof (GLib.Array))) {
			@value = GLib.Value (pspec.value_type);

			var array_value = property_node.get_array ();
			var array = new GLib.Array<GLib.Object> ();

			if (array_value != null) {
				var boxed_type = deserialize_property_with_boxed_type (pspec);

				array_value.foreach_element ((array_value, i, element) => {
					array.append_val (Json.gobject_deserialize (boxed_type, element));
				});
			}
			@value.set_boxed (array);

		} else if (pspec.value_type.is_a (typeof (GLib.Object))) {
			@value = GLib.Value (pspec.value_type);
			@value.set_object (Json.gobject_deserialize (pspec.value_type, property_node));

		} else {
			@value = property_node.get_value ();
		}
		return true;
	}

	public virtual Type deserialize_property_with_boxed_type (ParamSpec pspec) {
		return default_deserialize_property_with_boxed_type (pspec);
	}

	public Type default_deserialize_property_with_boxed_type (ParamSpec pspec) {
		return pspec.value_type;
	}
}

