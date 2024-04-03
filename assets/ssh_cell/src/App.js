import React, { useEffect, useRef, useState } from "react";
import { RiLockPasswordLine, RiInputMethodLine } from "@remixicon/react";
import classNames from "classnames";

export default function App({ ctx, payload }) {
  const [fields, setFields] = useState(payload.fields);

  useEffect(() => {
    ctx.handleEvent("update_field", ({ fields }) => {
      setFields((currentFields) => ({ ...currentFields, ...fields }));
    });
  }, []);

  function pushUpdate(field, value) {
    ctx.pushEvent("update_field", { field, value });
  }

  function handleChange(event, push = true) {
    const field = event.target.name;

    const value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;

    setFields({ ...fields, [field]: value });

    if (push) {
      pushUpdate(field, value);
    }
  }

  function handleBlur(event) {
    const field = event.target.name;

    pushUpdate(field, fields[field]);
  }

  function handleClick(event) {
    const button = event.target.name;
    ctx.pushEvent("button_click", { button });
  }

  return (
    <div className="font-sans">
      <Header>
        <FieldWrapper>
          <InlineLabel label="Host" />
          <div className="w-[140px]">
            <TextField
              name="host"
              value={fields.host}
              onChange={(event) => handleChange(event, false)}
              onBlur={handleBlur}
            />
          </div>
        </FieldWrapper>
        <FieldWrapper>
          <InlineLabel label="Username" />
          <div className="w-[140px]">
            <TextField
              name="username"
              value={fields.username}
              onChange={(event) => handleChange(event, false)}
              onBlur={handleBlur}
            />
          </div>
        </FieldWrapper>
        <FieldWrapper>
          <InlineLabel label="Password" />
          <SecretField
            ctx={ctx}
            toggleInputProps={{
              name: "use_password_secret",
              checked: fields.use_password_secret,
              onChange: handleChange,
            }}
            textInputProps={{
              name: "password",
              value: fields.password,
              onChange: (event) => handleChange(event, false),
              onBlur: handleBlur,
            }}
            secretInputProps={{
              name: "password_secret",
              value: fields.password_secret,
              onChange: handleChange,
            }}
            modalTitle="Set password"
            required
          />
        </FieldWrapper>
        <FieldWrapper>
          <InlineLabel label="Assign to" />
          <div className="w-[140px]">
            <TextField
              name="assign_to"
              value={fields.assign_to}
              onChange={(event) => handleChange(event, false)}
              onBlur={handleBlur}
            />
          </div>
        </FieldWrapper>
      </Header>
    </div>
  );
}

function Header({ children }) {
  return (
    <div className="align-stretch flex flex-wrap justify-start gap-4 rounded-lg border border-gray-300 border-b-gray-200 bg-blue-100 px-4 py-2">
      {children}
    </div>
  );
}

function FieldWrapper({ children }) {
  return <div className="flex items-center gap-1.5">{children}</div>;
}

function InlineLabel({ label }) {
  return (
    <label className="block text-sm font-medium uppercase text-gray-600">
      {label}
    </label>
  );
}

function TextField({
  label = null,
  value,
  type = "text",
  className,
  required = false,
  fullWidth = false,
  inputRef,
  startAdornment,
  ...props
}) {
  return (
    <div
      className={classNames([
        "flex max-w-full flex-col",
        fullWidth ? "w-full" : "w-[20ch]",
      ])}
    >
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "flex items-stretch overflow-hidden rounded-lg border bg-gray-50",
          required && !value ? "border-red-300" : "border-gray-200",
        ])}
      >
        {startAdornment}
        <input
          {...props}
          ref={inputRef}
          type={type}
          value={value}
          className={classNames([
            "w-full bg-transparent px-3 py-2 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
            className,
          ])}
        />
      </div>
    </div>
  );
}

function SecretField({
  ctx,
  toggleInputProps,
  textInputProps,
  secretInputProps,
  label = null,
  required = false,
  modalTitle = "Select secret",
}) {
  const secretInputRef = useRef(null);

  function selectSecret() {
    const preselectName = secretInputProps.value || "";

    ctx.selectSecret(
      (secretName) => {
        const input = secretInputRef.current;
        const value = secretName;
        // Simulate native input
        Object.getOwnPropertyDescriptor(
          HTMLInputElement.prototype,
          "value",
        ).set.call(input, value);
        input.dispatchEvent(new Event("input", { bubbles: true }));
      },
      preselectName,
      { title: modalTitle },
    );
  }

  const useSecret = toggleInputProps.checked;

  const inputTypeToggle = (
    <label className="flex items-center border-r border-gray-200 bg-gray-200 px-1.5 text-gray-600 hover:cursor-pointer hover:bg-gray-300">
      <input {...toggleInputProps} type="checkbox" className="hidden" />
      {useSecret ? (
        <RiLockPasswordLine size={24} />
      ) : (
        <RiInputMethodLine size={24} />
      )}
    </label>
  );

  return useSecret ? (
    <TextField
      {...secretInputProps}
      inputRef={secretInputRef}
      label={label}
      startAdornment={inputTypeToggle}
      required={required}
      onClick={selectSecret}
      className="cursor-pointer"
      readOnly
    />
  ) : (
    <TextField
      {...textInputProps}
      label={label}
      startAdornment={inputTypeToggle}
      required={required}
    />
  );
}

function Button({
  label,
  type = "button",
  className,
  fullWidth = false,
  onClick,
  startIcon,
  endIcon,
  ...props
}) {
  return (
    <button
      {...props}
      type={type}
      onClick={onClick}
      className={classNames([
        "flex items-center justify-center space-x-2 overflow-hidden rounded-lg border bg-gray-50 py-2 px-3 text-sm font-medium focus:outline-none",
        fullWidth ? "w-full" : "w-auto",
        "hover:bg-gray-100 active:bg-gray-200",
        className,
      ])}
    >
      {startIcon}
      {label}
      {endIcon}
    </button>
  );
}
