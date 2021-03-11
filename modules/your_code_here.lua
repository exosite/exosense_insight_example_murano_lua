local I = require('insight')

I.meta({
  name = 'Simple Insight',
  description = 'Awesome if this works',
  author = "Your Name Here",
  author_contact = "your@email.address.here",
})

I.add('adder', {
  name = "The Adder",
  description = "Adds a value to the signal",
  constants = {
    {
      name = "value",
      description = "A number",
      type = I.constant_types.NUMBER,
    },
  },
  inlets = {
    {
      name = 'Signal',
      description = 'The signal to add value to',
      tag = 'A',
      primitive_type = I.primitives.NUMERIC,
      data_type = {'NUMBER', 'TEMPERATURE'},
    }
  },
  outlets = {
      {
      name = 'Increased',
      description = 'The value added result',
      primitive_type = I.primitives.NUMERIC,
    }
  },
  fn = function(value, constants)
    return value + constants.value
  end
})

I.add('lowercase', {
  name = "Lowercase",
  description = "Lower case strings",
  constants = {
    {
      name = "onlyFirst",
      description = "Only lowercase the first character or all characters",
      type = I.constant_types.BOOLEAN,
    },
  },
  inlets = {
    {
      name = 'Signal',
      description = 'A string to change the case of',
      primitive_type = I.primitives.STRING,
    },
  },
  outlets = {
    {
      name = 'lo',
      description = 'Lower cased string',
      primitive_type = I.primitives.STRING,
    },
  },
  fn = function(value, constants)
    value = tostring(value)
    if constants.onlyFirst then
      return string.lower(string.sub(value, 1, 1)) .. string.sub(value, 2)
    else
      return string.lower(value)
    end
  end
})

I.add('bungle', {
  name = "Average-ish",
  description = "Not average, eventhough at first glance it looks like it",
  constants = { },
  inlets = {
    {
      name = 'Signal',
      description = 'The values to do maths on',
      primitive_type = I.primitives.NUMERIC,
    }
  },
  outlets = {
    {
      name = 'Resulting',
      description = 'The resulting value of our misunderstood computation',
      primitive_type = I.primitives.NUMERIC,
    }
  },
  fn = function(value, _, prior)
    if prior.A then
      return (value + prior.A) / 2
    else
      return value / 3
    end
  end
})

I.add_group('priadder', 'BR-009', {
  name = "The Private Adder",
  description = "Adds a value to the signal",
  constants = {
    {
      name = "value",
      description = "A number",
      type = I.constant_types.NUMBER,
    },
  },
  inlets = {
    {
      name = 'Signal',
      description = 'The signal to add value to',
      tag = 'A',
      primitive_type = I.primitives.NUMERIC,
      data_type = {'NUMBER', 'TEMPERATURE'},
    }
  },
  outlets = {
      {
      name = 'Increased',
      description = 'The value added result',
      primitive_type = I.primitives.NUMERIC,
    }
  },
  fn = function(value, constants)
    return value + constants.value
  end
})
