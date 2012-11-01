ko.observableHash = function (initialValues) {
    if (arguments.length == 0) {
        // Zero-parameter constructor initializes to empty array
        initialValues = {};
    }
    if ((initialValues !== null) && (initialValues !== undefined) && !(initialValues && (typeof initialValues  === "object")))
        throw new Error("The argument passed when initializing an observable hash must be an hash, or null, or undefined.");

    var result = ko.observable(initialValues);
    ko.utils.extend(result, ko.observableHash['fn']);
    return result;
}

ko.observableHash['fn'] = {
    'set': function(key, value) {
        this.valueWillMutate();
        this.peek()[key] = value;
        var self = this;
        if (ko.isObservable(value)) {
            value.subscribe(function() { self.valueHasMutated(); })
        }
        this.valueHasMutated();
    },
    'get': function(key) {
        return this.peek()[key];
    },
    'hasKey': function(key) {
        return this.peek().hasOwnProperty(key)
    }
}
