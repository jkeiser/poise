#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path('../subcontext_block', __FILE__)

module Poise
  module Provider
    module IncludeRecipe
      include SubContextBlock

      def include_recipe(*recipes)
        loaded_recipes = []
        context = global_run_context
        subcontext = subcontext_block(context) do
          recipes.each do |recipe|
            case recipe
            when String
              # Process normally
              Chef::Log.debug("Loading recipe #{recipe} via include_recipe (poise)")
              loaded_recipes += run_context.include_recipe(recipe)
            when Proc
              # Pretend its a block of recipe code
              fake_recipe = Chef::Recipe.new(cookbook_name, new_resource.recipe_name, run_context)
              fake_recipe.instance_eval(&recipe)
              loaded_recipes << fake_recipe
            end
          end
        end
        # Converge the new context.
        Chef::Runner.new(subcontext).converge
        subcontext.resource_collection.each do |r|
          # Insert the local resource into the global context
          context.resource_collection.insert(r)
          # Skip the iterator forward so we don't double-execute the inserted resource
          context.resource_collection.iterator.skip_forward
        end
        loaded_recipes
      end
    end
  end
end
