"use client";
import { useSpring, animated } from "@react-spring/web";
import { useState, useEffect } from "react";
import { useAccount } from "wagmi";

function HomePage() {
  const { isConnected } = useAccount(); // Only fetching isConnected, address removed
  const word = "Stablecoin.";
  const letters = word.split(""); // Split the word into individual letters
  const [index, setIndex] = useState(0);
  const [reverse, setReverse] = useState(false);

  // Keep track of client-side rendering to avoid hydration issues
  const [mounted, setMounted] = useState(false);

  // Spring config for the opacity and position of each letter
  const { opacity, x } = useSpring({
    opacity: 1,
    x: 0,
    from: { opacity: 0, x: 20 },
    config: { tension: 150, friction: 20 },
  });

  // Detect client-side rendering
  useEffect(() => {
    setMounted(true); // Set to true when the component is mounted on the client
  }, []);

  useEffect(() => {
    const timeout = setTimeout(() => {
      if (!reverse) {
        setIndex((prev) => (prev < letters.length ? prev + 1 : prev));
        if (index === letters.length) {
          setReverse(true); // Start deleting when the word is fully typed
        }
      } else {
        setIndex((prev) => (prev > 0 ? prev - 1 : prev));
        if (index === 0) {
          setReverse(false); // Start typing again when the word is fully deleted
        }
      }
    }, 150);

    return () => clearTimeout(timeout);
  }, [index, reverse, letters.length]);

  // Only render wallet connection status after the component is mounted
  return (
    <div className="h-screen p-10 flex flex-col justify-center items-center">
      <div className="space-y-8">
        <h1>
          Onboarding the Next Generation of Indian DeFi to Their own&nbsp;
          <br />
          <span
            style={{
              display: "inline-block",
              width: `${word.length}ch`,
              whiteSpace: "nowrap",
              textAlign: "left",
            }}
          >
            {letters.slice(0, index).map((letter, i) => (
              <animated.span
                key={i}
                style={{
                  color: "var(--secondary)",
                  opacity,
                  transform: x.to((x) => `translateX(${x}px)`),
                  display: "inline-block",
                }}
              >
                {letter}
              </animated.span>
            ))}
          </span>
        </h1>
        {/* Render wallet connection info only after component is mounted */}
        {mounted &&
          (isConnected ? (
            <div className="space-x-5"></div>
          ) : (
            <div className="flex justify-start items-center w-full">
              <h3>Connect wallet to get started.</h3>
            </div>
          ))}
      </div>
    </div>
  );
}

export default HomePage;