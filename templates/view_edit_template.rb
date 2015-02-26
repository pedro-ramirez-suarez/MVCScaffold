def view_edit_template model
fields = get_fields_edit model
entity_name = model['name']
name = entity_name
name_downcase = name.downcase

return <<template
@{
    ViewBag.page = "#{entity_name}";
    ViewBag.Title = "#{entity_name} | Edit";
    Layout = "~/Views/Shared/_Layout.cshtml";
}


<div class="page-header text-center">
    <h2>Edit</h2>
</div>
<form id="edit_#{name_downcase}_form" method="post" class="form-horizontal #{name_downcase}_form" action="Edit" role="form" data-bind="foreach: #{model['name']}s">
    #{fields}

    <div class="form-group">
        <div class="col-sm-offset-2 col-sm-10">
            <!-- Do NOT use name="submit" or id="submit" for the Submit button -->
            <button type="submit" class="btn btn-primary">Save</button>
            <button type="button" class="btn btn-danger" onclick="window.history.go(-1)">Cancel</button>
        </div>
    </div>
</form>

<script>
    require(["/Scripts/app/#{name}.controller.js", "/Scripts/app/#{name}.binding.js", "/Scripts/app/#{name}.validate.js", 'utils'], function (#{name_downcase}Controller, appViewModel, formValidator, utils) {
        utils.spinner.show();
        var promise = #{name_downcase}Controller.get#{name}("@ViewBag.id");
        promise.done(function (ajaxResult) {
            var model = ajaxResult.#{name_downcase};
            #{format_properties(model, 'create_edit')}  
            appViewModel.add(model);
            formValidator.initViewModel(appViewModel);
            formValidator.initValidator();

            utils.spinner.hide();
        });
    });
</script>
template
end

def get_fields_edit model
    elements = model.at_xpath("fields").elements
    fields = ""
    entity_name = ""

    if elements.xpath("//entity").length > 1
        entity_name = elements.xpath("//entity").first['name'] + "."
    end

    elements.each do |node|    
        property_name = node.name

        if property_name.to_s == "Id"
            fields += @form_fields[:hidden] %[property_name, "data-bind='value: #{entity_name}#{property_name}'"]
        elsif node.at_css("SelectFrom")
            fields += get_selectfrom_template model, 'edit_create', node.attribute('SelectFrom')
        elsif node.at_css("HasOne")
            reference = node.attribute('HasOne')
            nkg_obj = node.xpath("//entity")
            has_one = nkg_obj.search("entity[objectName=#{reference}]")
            has_one_name = has_one.attribute('name')

            fields += @form_fields[:button] %[has_one_name, "data-bind=\"attr:{href: '/#{has_one_name}/edit/' + #{entity_name}#{property_name}}\"", property_name]
        elsif node.attribute('validator').to_s == "date"
            fields += get_datepicker_template(model, 'edit_create')
        else
            fields += @form_fields[:text] %[property_name, property_name, "data-bind='value: #{entity_name}#{property_name}'"]
        end
        
    end

    fields += get_has_many_template(model, 'edit')
    fields

end
