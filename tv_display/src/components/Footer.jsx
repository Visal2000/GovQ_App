import React from 'react';

const Footer = ({ message }) => {
  return (
    <div className="tv-footer">
      <div className="marquee">
        {message}
      </div>
    </div>
  );
};

export default Footer;
