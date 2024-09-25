import { useState } from "react";
export interface HamburgerProps {
  /** Callback function, which should be executed on click */
  onClick: () => void;

  /** Initial state of our button */
  isInitiallyOpen?: boolean;
}

export function Hamburger(props: HamburgerProps) {
  const { onClick, isInitiallyOpen } = props;
  const [isOpen, setIsOpen] = useState<boolean>(isInitiallyOpen ?? false);

  const handleClick = () => {
    setIsOpen((prev) => !prev);
    onClick();
  };

  return (
    <button
      onClick={handleClick}
      type="button"
      className={`w-8 h-8 flex bg-transparent justify-around flex-col flex-wrap z-10 cursor-pointer${
        isOpen ? "" : ""
      }`}
    >
      <div
        className={` block w-8 h-[0.15rem] rounded transition-all origin-[1px] ${
          isOpen ? "rotate-45 bg-black" : "bg-white rotate-0"
        }`}
      />
      <div
        className={` block w-8 h-[0.15rem] rounded transition-all origin-[1px] ${
          isOpen ? "translate-x-full bg-transparent" : "bg-white translate-x-0"
        }`}
      />
      <div
        className={` block w-8 h-[0.15rem] rounded transition-all origin-[1px] ${
          isOpen ? "rotate-[-45deg] bg-black" : "rotate-0 bg-white"
        }`}
      />
    </button>
  );
}
