def model_template model
fields = get_fields_for_model model.at_xpath("fields").elements

return <<template
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Needletail.DataAccess.Attributes;
using DataAccess.Scaffold.Attributes;

namespace #{@solution_name_sans_extension}.Models
{
    public class #{model["name"]}
    {
        #{fields}
    }
}
template
end

def get_fields_for_model elements
    fields = ""

    elements.each do |node|    
        params = ""
        if node.has_attribute?("hasOne")
            if node.at_xpath("HasOne").attribute("ReferencedField").to_s == "Id"
               type = "int" 
            end
        elsif node.has_attribute?("hasMany")
            type = "List<int>"
        elsif node.name == "Id"
            type = elements.xpath("//entity").first['primaryKeyType']
        else
            type = "string"
        end

        attrParams = node.at_css("Validator") ? node.at_css("Validator").attribute_nodes : []


        if attrParams.length > 0
            attrParams.each do |attrb|
                params += "#{attrb.to_s}, "
            end
            params = "(#{params.chomp(', ')})"
        end

        attributes = get_attributes node


        if node.name == "Id"
            attributes += "[TableKey(CanInsertKey = true)]"
        end

        fields += "
        #{attributes}
        public #{type} #{node.name} { get; set; }
        "
    end
    fields
end

def get_attributes property
    result = ""

    if property.has_attribute?('validator')
        attributes = property.attribute('validator').to_s().split(' ')
        attributes.map! { |attribute| 
            param = property.search("@#{attribute.capitalize}")

            param = param.empty? ? "" : "(#{param})"

            attribute = @dictionary_validators[attribute] || next
            

            result += "[#{attribute}#{param}]"
        }
    end

    result
end