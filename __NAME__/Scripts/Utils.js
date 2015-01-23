define(['moment'], function (moment) {
    var formatDate = function (date) {  
        var result = moment(date);
        return result;
    };

    var utils = {        
      formatDate: formatDate,
      makeAjaxCall: function (url, data) {
            return $.ajax({
                url: url,
                type: 'POST',
                dataType: 'json',
                data: data
            });
      }
    };

    return utils;
});