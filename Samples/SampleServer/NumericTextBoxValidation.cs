using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Controls;

namespace SampleServer
{
    public class NumericTextBoxValidation: ValidationRule
    {
        public override ValidationResult Validate(object value, System.Globalization.CultureInfo cultureInfo)
        {
            if (String.IsNullOrEmpty((string) value))
                return ValidationResult.ValidResult;
            int dummy;
            if (Int32.TryParse((string) value, out dummy))
            {
                if (dummy < 0 || dummy > 100)
                    return new ValidationResult(false, "number should be between 0 and 100");
                return ValidationResult.ValidResult;
            }
            else
            {
                return new ValidationResult(false, "Value is not of integer type");
            }
        }
    }
}
