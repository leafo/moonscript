import with_dev from require "spec.helpers"

describe "filesystem stub helpers", ->
  local create_io_stubs

  dev_loaded = with_dev ->
    import create_io_stubs from require "spec.fs_stubs"

  describe "internal tests", ->
    local fs_root, new_node, add_child, remove_child, traverse_entire_path, traverse_parent

    before_each ->
      {:fs_root, :traverse_entire_path, :traverse_parent, :new_node, :add_child, :remove_child} = create_io_stubs!

    describe "add_child", ->
      local child_name, child_node
      before_each ->
        child_node = new_node "file"
        child_name = "foo"

      it "should increase child_count by 1", ->
        old_count = fs_root.child_count

        add_child fs_root, child_name, child_node

        assert.are.same old_count + 1, fs_root.child_count

      it "should make the child reachable from the parent under the given name", ->
        assert.is.nil fs_root.children[child_name]

        add_child fs_root, child_name, child_node

        assert.is.not.Nil fs_root.children[child_name]
        assert.are.same child_node, fs_root.children[child_name]

      it "should error if there is already a child with that name", ->
        add_dup = () ->
          add_child fs_root, child_name, child_node
        add_dup!

        assert.has.error add_dup

      it "should error if called on a file node", ->
        parent_node = new_node "file"

        assert.has.error () ->
          add_child parent_node, child_name, child_node

    describe "remove_child", ->
      local child_name, child_node
      before_each ->
        child_node = new_node "file"
        child_name = "foo"
        add_child fs_root, child_name, child_node


      it "should decrease child_count by 1", ->
        old_count = fs_root.child_count

        remove_child fs_root, child_name

        assert.are.same old_count - 1, fs_root.child_count

      it "should mean no child is reachable from the parent under the given name", ->
        assert.is.not.Nil fs_root.children[child_name]
        assert.are.same child_node, fs_root.children[child_name]

        remove_child fs_root, child_name

        assert.is.nil fs_root.children[child_name]

      it "should error if there is no child with that name", ->
        remove_dup = () ->
          remove_child fs_root, child_name
        remove_dup!

        assert.has.error remove_dup

      it "should error if called on a file node", ->
        parent_node = new_node "file"

        assert.has.error () ->
          remove_child parent_node, child_name

    describe "path traversal tests", ->
      local valid_path, invalid_path, file_path, previous_node, last_node

      before_each ->
        import iterate_path from require "moonscript.cmd.path_handling"
        valid_path = "/foo/bar/baz"
        invalid_path = "/foo/boo/baz"
        file_path = "/foo/bar/file"
        current_node = fs_root
        previous_node = nil

        for element in iterate_path valid_path
          child_node = new_node "directory"
          add_child current_node, element, child_node
          previous_node = current_node
          current_node = child_node
        last_node = current_node

        -- Add the file child in file_path
        add_child fs_root.children["foo"].children["bar"],
          "file", (new_node "file")

      describe "traverse_entire_path", ->
        it "returns the node of the last element for a valid path", ->
          fs_node, error_message = traverse_entire_path valid_path, fs_root

          assert.is.Nil error_message
          assert.is.not.Nil fs_node
          assert.are.same last_node, fs_node

        it "returns nil and error message if any element in the path does not exist", ->
          fs_node, error_message = traverse_entire_path invalid_path, fs_root

          assert.is.nil fs_node
          assert.are.same "No such path", error_message

        it "returns nil and error message if any element save the last in the path is not a directory", ->
          fs_node, error_message = traverse_entire_path file_path .. "/nak", fs_root

          assert.is.nil fs_node
          assert.are.same "Non-final element in path is a file", error_message

      describe "traverse_parent", ->
        it "returns the node of the parent of the last element for a valid path, along with the last element's name", ->
          fs_node, child_name = traverse_parent valid_path, fs_root

          assert.is.not.Nil fs_node
          assert.are.same previous_node, fs_node
          assert.are.same "baz", child_name

        it "returns nil and error message if any element in the path does not exist", ->
          fs_node, error_message = traverse_entire_path invalid_path, fs_root

          assert.is.nil fs_node
          assert.are.same "No such path", error_message

        it "returns nil and error message if any element save the last in the path is not a directory", ->
          fs_node, error_message = traverse_entire_path file_path .. "/nak", fs_root

          assert.is.nil fs_node
          assert.are.same "Non-final element in path is a file", error_message

  describe "stub tests", ->
    local stubs, fs_root, new_node, add_child, remove_child, traverse_entire_path, traverse_parent
    before_each ->
      {:stubs, :fs_root, :traverse_entire_path, :traverse_parent, :new_node, :add_child, :remove_child} = create_io_stubs!

    describe "lfs", ->
      local lfs
      before_each ->
        lfs = stubs.lfs

      describe "attributes()", ->
        it "", ->
          nil -- TODO

        it "", ->
          nil -- TODO

      describe "mkdir()", ->
        local dir_name, parent_node, parent_name, dir_path, new_dir_name

        before_each ->
          parent_node = new_node "directory"
          parent_name = "foo"
          add_child fs_root, parent_name, parent_node
          new_dir_name = "bar"
          dir_path = "/#{parent_name}/#{new_dir_name}"

        it "should make a new child reachable at the given path", ->
          fs_node, error_message = traverse_entire_path dir_path
          assert.is.Nil fs_node
          assert.are.same "No such path", error_message

          is_ok, error_message, error_code = lfs.mkdir dir_path

          assert is_ok
          assert.is.Nil error_message
          assert.is.Nil error_code
          fs_node, error_message = traverse_entire_path dir_path
          assert.is.Nil error_message
          assert.is.not.Nil fs_node
          assert.are.same "table", type(fs_node)
          assert.are.same parent_node.children[new_dir_name], fs_node

        it "should fail if there is no existing parent for the given path", ->
          remove_child fs_root, parent_name

          is_ok, error_message, error_code = lfs.mkdir dir_path

          assert.is.Nil is_ok
          assert.is.not.Nil error_message
          assert.is.not.Nil error_code
          assert.are.same "No such directory", error_message

      describe "touch()", ->
        it "", ->
          nil -- TODO
