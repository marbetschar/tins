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
* Authored by: Marco Betschart <elementary-tins@marco.betschart.name>
*/

public abstract class LXD.Object : GLib.Object, Json.Serializable {

	public unowned ParamSpec? find_property (string name) {
		return ((ObjectClass) get_type ().class_ref ()).find_property (name);
	}

	public virtual Json.Node serialize_property (string property_name, Value @value, ParamSpec pspec) {
		Type boxed_value_type;
	    bool boxed_in_array;
	    property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);

		if (@value.type ().is_a (typeof (GLib.GenericArray))) {

			if (boxed_value_type.is_a (typeof (GLib.Object))) {
			    unowned GLib.GenericArray<GLib.Object> array_value = @value as GLib.GenericArray<GLib.Object>;

			    if (array_value != null){
				    var array = new Json.Array.sized (array_value.length);

				    for(var i = 0; i < array_value.length; i++) {
					    array.add_element (Json.gobject_serialize (array_value.get (i)));
				    }

				    var node = new Json.Node (Json.NodeType.ARRAY);
				    node.set_array (array);
				    return node;
			    }

			} else if (boxed_value_type.is_a (typeof (string))){
			    unowned GLib.GenericArray<string> array_value = @value as GLib.GenericArray<string>;

			    if (array_value != null){
				    var array = new Json.Array.sized (array_value.length);

				    for(var i = 0; i < array_value.length; i++) {
					    array.add_string_element (array_value.get (i));
				    }

				    var node = new Json.Node (Json.NodeType.ARRAY);
				    node.set_array (array);
				    return node;
			    }

			} else {
			    warning (@"GLib.GenericArray serialization not supported for boxed type: $(boxed_value_type.name ())");
			}

		} else if (@value.type ().is_a (typeof (GLib.HashTable))) {
			var object = new Json.Object ();

			if (boxed_in_array) {
				unowned GLib.HashTable<string,GLib.GenericArray<GLib.Object>> hash_table = @value as HashTable<string, GLib.GenericArray<GLib.Object>>;

				if (hash_table != null) {
					hash_table.foreach ((key, array_value) => {
						var array = new Json.Array.sized (array_value.length);

						for(var i = 0; i < array_value.length; i++) {
							array.add_element (Json.gobject_serialize (array_value.get (i)));
						}

						var node = new Json.Node (Json.NodeType.ARRAY);
						node.set_array (array);
						object.set_member (key, node);
					});
				}

			} else if (boxed_value_type.is_a (typeof (string))) {
				unowned GLib.HashTable<string, string> hash_table = @value as HashTable<string, string>;

				if (hash_table != null) {
					hash_table.foreach ((key, val) => {
						object.set_string_member (key, val);
					});
				}

			} else if (boxed_value_type.is_a (typeof (GLib.Object))) {
				unowned GLib.HashTable<string, GLib.Object> hash_table = @value as HashTable<string, GLib.Object>;

				if (hash_table != null) {
					hash_table.foreach ((key, object_value) => {
						object.set_member (key, Json.gobject_serialize (object_value));
					});
				}

			} else {
			   warning (@"GLib.HashTable serialization not supported for boxed type: $(@value.type ().name ())");
			}

			var node = new Json.Node (Json.NodeType.OBJECT);
			node.set_object (object);
			return node;
		}

		return default_serialize_property (property_name, @value, pspec);
	}

	public virtual bool deserialize_property (string property_name, out Value @value, ParamSpec pspec, Json.Node property_node) {
		Type boxed_value_type;
	    bool boxed_in_array;
	    property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);

		if (pspec.value_type.is_a (typeof (GLib.GenericArray))) {
			@value = GLib.Value (pspec.value_type);

			var array_value = property_node.get_array ();

			if (boxed_value_type.is_a (typeof (GLib.Object))) {
				var array = new GLib.GenericArray<GLib.Object> ();

				if (array_value != null) {
					array_value.foreach_element ((array_value, i, element) => {
						if (!element.is_null ()) {
							array.add (Json.gobject_deserialize (boxed_value_type, element));
						}
					});
				}
				@value.set_boxed (array);

			} else if (boxed_value_type.is_a (typeof (string))){
				var array = new GLib.GenericArray<string> ();

				if (array_value != null) {
					array_value.foreach_element ((array_value, i, element) => {
						array.add (element.get_string ());
					});
				}
				@value.set_boxed (array);

			} else {
			    warning (@"GLib.GenericArray deserialization not supported for boxed type: $(boxed_value_type.name ())");
			}

		} else if (pspec.value_type.is_a (typeof (GLib.HashTable))) {
			@value = GLib.Value (pspec.value_type);

			var object_value = property_node.get_object ();

			if (object_value != null) {
				if (boxed_in_array) {
					var hash_table = new GLib.HashTable<string, GLib.GenericArray<GLib.Object>> (str_hash, str_equal);

					object_value.foreach_member ((object, member_name, member_node) => {
						var array_value = member_node.get_array ();
						var array = new GLib.GenericArray<GLib.Object> ();

						if (array_value != null) {
							array_value.foreach_element ((array_value, i, element) => {
								if (!element.is_null ()) {
									array.add (Json.gobject_deserialize (boxed_value_type, element));
								}
							});
						}
						hash_table.@set (member_name, array);
					});
					@value.set_boxed (hash_table);

				} else if (boxed_value_type.is_a (typeof (string))) {
					var hash_table = new GLib.HashTable<string, string> (str_hash, str_equal);
					object_value.foreach_member ((object, member_name, member_node) => {
						hash_table.@set (member_name, member_node.get_string ());
					});
					@value.set_boxed (hash_table);

				} else if (boxed_value_type.is_a (typeof (GLib.Object))) {
					var hash_table = new GLib.HashTable<string, GLib.Object> (str_hash, str_equal);
					object_value.foreach_member ((object, member_name, member_node) => {
						if (!member_node.is_null ()) {
							hash_table.@set (member_name, Json.gobject_deserialize (boxed_value_type, member_node));
						}
					});
					@value.set_boxed (hash_table);

				} else {
					warning (@"GLib.HashTable deserialization not supported for boxed value of type: $(boxed_value_type.name ())");
				}
			}

		} else if (pspec.value_type.is_a (typeof (GLib.Object))) {
			@value = GLib.Value (pspec.value_type);
			if (!property_node.is_null ()) {
				@value.set_object (Json.gobject_deserialize (pspec.value_type, property_node));
			}

		} else {
			@value = property_node.get_value ();
		}
		return true;
	}

	/**
	 * GLib boxed types such as GLib.GenericArray or GLib.HashTable
	 * don't carry the type of their boxed values at runtime.
	 *
	 * Overide this method to provide the boxed value type for such properties.
	 */
	public virtual void property_boxed_value_type_with_param_spec (ParamSpec pspec, out Type boxed_value_type, out bool boxed_in_array) {
		default_property_boxed_value_type_with_param_spec (pspec, out boxed_value_type, out boxed_in_array);
	}

	/**
	 * GLib boxed types such as GLib.GenericArray or GLib.HashTable
	 * don't carry the type of their boxed values at runtime.
	 *
	 * Call this method to fall back to the default implementation.
	 */
	public void default_property_boxed_value_type_with_param_spec (ParamSpec pspec, out Type boxed_value_type, out bool boxed_in_array) {
	    boxed_value_type = pspec.value_type;
	    boxed_in_array = false;
	}
}

