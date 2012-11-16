ko.bindingHandlers['polymorphic_checked'] = {
    'init': function (element, valueAccessor) {
        var updateHandler = function() {
            var modelValue = valueAccessor(), unwrappedValue = ko.utils.unwrapObservable(modelValue);
            var existingEntryIndex = -1;
            jQuery.each(unwrappedValue, function(idx,item){
               if ((item['id'] == element.value) && (item['type'] == element.getAttribute('itemtype')))
                   existingEntryIndex = idx;
            })
            if (element.checked && (existingEntryIndex < 0))
                modelValue.push({id: element.value, type: element.getAttribute('itemtype')});
            else if ((!element.checked) && (existingEntryIndex >= 0))
                modelValue.splice(existingEntryIndex, 1);
        };
        ko.utils.registerEventHandler(element, "click", updateHandler);
    },
    'update': function (element, valueAccessor) {
        var value = ko.utils.unwrapObservable(valueAccessor());
        jQuery.each(value, function(idx,item){
            if ((item['id'] == element.value) && (item['type'] == element.getAttribute('itemtype')))
                element.checked = true;
        })
    }
};
