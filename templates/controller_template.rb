def controller_template model, keytype, entityNameSpace, root_namespace
    name = model['name']
    name_downcase = name.downcase
    viewModelSufix = ""    
    useRepositories = true

    if model.xpath("//entity").length > 1
        viewModelSufix = "ViewModel"    
        useRepositories = false
    end
    
return <<template
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Needletail.DataAccess;
using System.Configuration;
using System.Web.Script.Serialization;
using #{@solution_name_sans_extension}.Repositories;
using #{entityNameSpace};
#{root_namespace}


namespace #{@solution_name_sans_extension}.Controllers
{

    //Basic Controller template, avoid adding bussiness logic code here, use the Repository instead
    public class #{name}Controller : Controller
    {
        
        #{get_repositories(model, 'declaration')}

        public #{name}Controller() {

            //Remove this line if you want to use dependency injection 
            #{get_repositories(model, 'init')}
        }

        //
        // GET: /#{name}/

        public ActionResult Index()
        {
            var #{name_downcase}s = #{name_downcase}Repository.GetAll();
            ViewBag.#{name}s = new JavaScriptSerializer().Serialize(#{name_downcase}s);
            
            return View();
        }

        //
        // GET: /#{name}/Details/id

        public ActionResult Details(#{keytype} id)
        {
            #{(get_repositories(model, 'use') if useRepositories)}
            #{init_view_model(model)}
            
            return View();
        }

        //
        // GET: /#{name}/Create

        public ActionResult Create()
        {
            #{(useRepositories ? 
            "var #{name} = new #{name}();
            ViewBag.#{name} = new JavaScriptSerializer().Serialize(#{name});" : 
            "var viewModel = new #{name}ViewModel();
            viewModel.FillData(primaryKey: new Guid());;
            ViewBag.#{name} = new JavaScriptSerializer().Serialize(viewModel);")}
            return View();
        }

        //
        // POST: /#{name}/Create

        [HttpPost]
        public ActionResult Create(#{name}#{viewModelSufix} model)
        {

            #{(useRepositories ? "model.Id = Guid.NewGuid();" +
            "#{name_downcase}Repository.Insert(model);" : 
            "model.#{name}.Id = Guid.NewGuid();
            #{get_has_ones(model)}
             model.Save();")}

            return Json(new { result = "Redirect", url = Url.Action("Index", "#{name}") });
        }

        //
        // GET: /#{name}/Edit/id

        public ActionResult Edit(#{keytype} id)
        {
            #{(useRepositories ? "var #{name_downcase} = #{name_downcase}Repository.GetSingle(where: new { Id = id });
                ViewBag.#{name} = new JavaScriptSerializer().Serialize(#{name_downcase});" : "var viewModel = new #{name}ViewModel();
                viewModel.FillData(primaryKey: id);
                ViewBag.#{name} = new JavaScriptSerializer().Serialize(viewModel);")}
            return View();
        }

        //
        // POST: /#{name}/Edit/id

        [HttpPost]
        public ActionResult Edit(#{name}#{viewModelSufix} model)
        {
            #{(useRepositories ? 
            "var result = #{name_downcase}Repository.UpdateWithWhere(values: model,
                            where: new {Id = model.Id});" : 
            "model.Save();")}

            return Json(new { result = "Redirect", url = Url.Action("Index", "#{name}") });
        }


        //
        // POST: /#{name}/Delete/5

        [HttpPost, ActionName("Delete")]
        public bool Delete(#{keytype} id)
        {

            var result = #{name_downcase}Repository.Delete(where: new {Id = id});
            return result;
        }

        [HttpPost]
        public JsonResult GetAll#{name}(int page_num, int rows_per_page)
        {
            var list = new List<dynamic>();
            var sortField = this.Request.Form["sorting[0][field]"];
            var sort = this.Request.Form["sorting[0][order]"];

            var registers = #{name_downcase}Repository.GetAll().ToList();
            var rows = registers.Skip((page_num - 1) * rows_per_page).Take(rows_per_page);

            if (DynamicOrdering.ContainsKey(sortField))
            {
                rows = (sort == "descending") ? rows.OrderByDescending(DynamicOrdering[sortField]) : rows.OrderBy(DynamicOrdering[sortField]);
            }

            
            foreach (var row in rows)
            {
                var objId = row.Id.ToString();
                list.Add(new
                {
                    #{get_properties(model, 'object')},
                    edit = string.Format("<a href = \\"/#{name_downcase}/edit/{0}\\">Edit</a>", objId),
                    details = string.Format("<a href = \\"/#{name_downcase}/Details/{0}\\">Details</a>", objId),
                    delete = string.Format("<a href = \\"/#{name_downcase}/delete/{0}\\">Delete</a>", objId)
                });
            }

            var result = Json(new { total_rows = registers.Count, page_data = list });
            return result;
        }

        public Dictionary<String, Func<#{name}, IComparable>> DynamicOrdering = new Dictionary<string, Func<#{name}, IComparable>>
                                                                                         {
                                                                                             #{get_properties(model, 'dictionary')}
                                                                                         };
    }
}
template
end

def get_repositories model, action
    repositories = ""

    entity_name = model['name']
    if action == "declaration"
        repositories += "
        #{entity_name}Repository #{entity_name.downcase}Repository;"    
    elsif action == "init"
        repositories += "
        #{entity_name.downcase}Repository = new #{entity_name}Repository();"
    elsif action == "use"
            repositories += "
        var #{entity_name} = #{entity_name.downcase}Repository.GetSingle(where: new {Id = id});"        
    end 
        
    repositories
        
end

def init_view_model model
    name = model['name']
    view_bag = "ViewBag.#{name} = new JavaScriptSerializer().Serialize(#{name});"


    if model.xpath("//entity").length > 1
        view_bag = "
            var viewModel = new #{name}ViewModel();
            viewModel.FillData(primaryKey: id);
            ViewBag.#{name} = new JavaScriptSerializer().Serialize(viewModel);"
    end

    view_bag
end

def get_has_ones model
has_ones = ""
model.xpath("//@HasOne").each do |node|
    main_entity_name = model['name']
    property_name = node
    id_name = node.parent.name

    nkg_obj = node.xpath("//entity")
    has_one = nkg_obj.search("entity[objectName=#{property_name}]")
    has_one_name = has_one.attribute('name')

    has_ones += "
        model.#{main_entity_name}.#{id_name} = Guid.NewGuid();
        model.#{property_name} = new #{has_one_name}(){Id = model.#{main_entity_name}.#{id_name}};"
end

has_ones
end

def get_properties model, type
    name_downcase = model['name'].downcase
    elements = model.at_xpath("fields").elements
    fields = ""

    elements.each do |node|    
        property_name = node.name

        case type
        when "dictionary"
            fields += "{\"#{property_name}\",opt => opt.#{property_name}},"
        when "object"
            fields += "
                    #{property_name} = row.#{property_name},"
        end
    end

    fields.chomp(',')

end