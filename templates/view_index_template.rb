def view_index_template model, use_bs_grid = false
    name = model['name']
    name_downcase = name.downcase

    grid_file = ", '/Scripts/app/#{name}.grid.js'"
    grid_container = "<div id='bs_grid_#{name_downcase}'></div>"

return <<template
@{
    ViewBag.Title = "Index";
    Layout = "~/Views/Shared/_Layout.cshtml";
    
}

<input type="hidden" id="refresh" value="no">

<h2>#{name}</h2>

#{(use_bs_grid ? grid_container: get_table(model))}

<a href="/#{name}/Create" class="btn btn-primary">Add</a>
    
<script>
    require(["/Scripts/app/#{name}.binding.js", 'underscore', 'moment' #{grid_file if use_bs_grid}], function (modelBinding, _, moment) {
        var model = JSON.parse('@Html.Raw(ViewBag.#{name}s)');
            
        _.each(model, function(item) {
            #{format_properties(model, 'index')}
            modelBinding.add(item);
        });
    });
</script>
template
end

def get_labels_index model
    labels = ""
    elements = model.at_xpath("fields").elements


    elements.each do |node|    
        name = node.name.to_s
        next if (node.name.to_s == "Id" || node.has_attribute?("SelectFrom") || 
            node.has_attribute?("HasOne")) || node.xpath("@validator='date'") ||
            (name[(name.length() -2)...name.length] == "Id")

        property_name = node.name
        labels += "
            <td>
                <label class='display-label' data-bind='text: #{property_name}'></label>
            </td>"
    end
    labels
end

def get_columns_names model
    labels = ""
    elements = model.at_xpath("fields").elements


    elements.each do |node|    
        name = node.name.to_s
        next if (node.name.to_s == "Id" || node.has_attribute?("SelectFrom") || 
            node.has_attribute?("HasOne")) || node.xpath("@validator='date'") ||
            (name[(name.length() -2)...name.length] == "Id")

        property_name = node.name
        labels += "
            <th>
                #{property_name}
            </th>"
    end
    labels
end

def get_table model
    name = model['name']
return <<template
    <table class="table table-striped" >
        <thead>
            <tr>
                #{get_columns_names(model)}
            </tr>
        </thead>
        <tbody data-bind="foreach: #{name}s">
            <tr>
                #{get_labels_index model}
                <td><a data-bind="attr: {href: '/#{name}/Details/' + Id}">Details</a></td>
                <td><a data-bind="attr: {href: '/#{name}/Edit/' + Id}">Edit</a></td>
                <td><a data-bind="click: $parent.remove">Remove</a></td>
            </tr>
        </tbody>
    </table>
template
end