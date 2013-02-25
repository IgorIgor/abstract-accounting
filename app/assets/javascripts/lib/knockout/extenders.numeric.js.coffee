ko.extenders.numeric = (target, precision) ->
  result = ko.computed(
    read: target
    write: (newValue) ->
      current = target()
      roundingMultiplier = Math.pow(10, precision)
      newValueAsNum = if isNaN(newValue) then target() else parseFloat(+newValue)
      valueToWrite = Math.round(newValueAsNum * roundingMultiplier) / roundingMultiplier
      if valueToWrite != current
          target(valueToWrite)
      else if newValue != current
          target.notifySubscribers(valueToWrite)
  )
  result(target())
  result
