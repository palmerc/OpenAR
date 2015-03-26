//
//  TransformationType.h
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#ifndef TransformationType_hpp
#define TransformationType_hpp

#include <Eigen/Eigen>

class TransformationImpl;



class Transformation
{
public:
    virtual ~Transformation() {}
    static std::shared_ptr<Transformation> create();
    static std::shared_ptr<Transformation> create(const Eigen::Matrix3f &rotation, const Eigen::Vector3f &translation);

    Eigen::Matrix3f &rotation();
    Eigen::Vector3f &translation();

    const Eigen::Matrix3f &rotation() const;
    const Eigen::Vector3f &translation() const;

    Eigen::Matrix4f getMatrix4f() const;
    Eigen::Matrix4f getInverted() const;

private:
    friend class TransformationImpl;
    Transformation() {}
    const TransformationImpl *impl() const;
    TransformationImpl *impl();
};

#endif
