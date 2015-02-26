def view_create_template model
fields = get_fields model
entity_name = model['name']
name = entity_name
name_downcase = name.downcase

return <<template
@{
    ViewBag.page = "#{entity_name}";
    ViewBag.Title = "#{entity_name} | Create";
    Layout = "~/Views/Shared/_Layout.cshtml";
}


<div class="page-header text-center">
    <h2>Create</h2>
</div>
<form id="create_#{entity_name.downcase}_form" method="post" class="form-horizontal #{model['name'].downcase}_form" action="create" role="form" data-bind="foreach: #{entity_name}s">
    #{fields}
    <div class="form-group">
        <div class="col-sm-offset-2 col-sm-10">
            <!-- Do NOT use name="submit" or id="submit" for the Submit button -->
            <button type="submit" class="btn btn-primary">Create</button>

        </div>
    </div>
</form>
<script>
    require(["/Scripts/app/#{name}.controller.js", "/Scripts/app/#{name}.binding.js", "/Scripts/app/#{name}.validate.js", 'utils'], function (#{name_downcase}Controller, appViewModel, formValidator, utils) {
        utils.spinner.show();
        var promise = #{name_downcase}Controller.get#{name}("00000000-0000-0000-0000-000000000000");
        promise.done(function (ajaxResult) {
            var model = ajaxResult.#{name_downcase};
            #{format_properties(model, 'create_edit')}
            appViewModel.add(model);
            formValidator.initViewModel(appViewModel);
            formValidator.initValidator();
        });

        utils.spinner.hide();
    });
</script>
template
end

def get_fields model
    elements = model.at_xpath("fields").elements
    fields = ""
    entity_name = ""

    if elements.xpath("//entity").length > 1
        entity_name = elements.xpath("//entity").first['name'] + "."
    end

    elements.each do |node|    
        property_name = node.name
        next if property_name.to_s == "Id"

        if node.at_css("SelectFrom")
            fields += get_selectfrom_template model, 'edit_create', node.attribute('SelectFrom')
        elsif node.at_css("HasOne")
            next
        elsif node.attribute('validator').to_s == "date"
            fields += get_datepicker_template(model, 'edit_create')
        else
            fields += @form_fields[:text] %[property_name, property_name, "data-bind='value: #{entity_name}#{property_name}'" ]
        end
        
    end
    fields

end
