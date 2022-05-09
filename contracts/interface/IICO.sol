// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IICO {
    function getReferee(address _referal) external view returns(address[] memory);

    function getReferal(address _referee) external view returns(address);
}